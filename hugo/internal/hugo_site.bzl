def relative_path(src, dirname):
    """Given a src File and a directory it's under, return the relative path.

    Args:
        src: File(path/to/site/content/docs/example1.md)
        dirname: string("content")

    Returns:
        string
    """

    # Find the last path segment that matches the given dirname, and return that
    # substring.
    if src.short_path.startswith("/"):
        i = src.short_path.rfind("/%s/" % dirname)
        if i == -1:
            fail("failed to get relative path: couldn't find %s in %s" % (dirname, src.short_path))
        return src.short_path[i + 1:]

    i = src.short_path.rfind("%s/" % dirname)
    if i == -1:
        fail("failed to get relative path: couldn't find %s in %s" % (dirname, src.short_path))
    return src.short_path[i:]

def copy_to_dir(ctx, srcs, dirname):
    outs = []
    for i in srcs:
        if i.is_source:
            o = ctx.actions.declare_file(relative_path(i, dirname))
            ctx.actions.run(
                inputs = [i],
                executable = "cp",
                arguments = ["-r", "-L", i.path, o.path],
                outputs = [o],
            )
            outs.append(o)
        else:
            outs.append(i)
    return outs

def _hugo_site_impl(ctx):
    hugo = ctx.executable.hugo
    hugo_inputs = []
    hugo_outputdir = ctx.actions.declare_directory(ctx.label.name)
    hugo_outputs = [hugo_outputdir]
    hugo_args = []

    if ctx.file.config == None and (ctx.files.config_dir == None or len(ctx.files.config_dir) == 0):
        fail("You must provide either a config file or a config_dir")

    # Copy the config file into place
    config_dir = ctx.files.config_dir

    if config_dir == None or len(config_dir) == 0:
        config_file = ctx.actions.declare_file(ctx.file.config.basename)
        
        ctx.actions.run_shell(
            inputs = [ctx.file.config],
            outputs = [config_file],
            command = 'cp -L "$1" "$2"',
            arguments = [ctx.file.config.path, config_file.path],
        )

        hugo_inputs.append(config_file)

        hugo_args += [
            "--source",
            config_file.dirname,
        ]
    else:
        placeholder_file = ctx.actions.declare_file(".placeholder")
        ctx.actions.write(placeholder_file, "paceholder", is_executable=False)
        hugo_inputs.append(placeholder_file)
        #  placeholder_file.dirname + "/config/_default/config.yaml",
        hugo_args += [
            "--source", placeholder_file.dirname
        ]

    # Copy all the files over
    for name, srcs in {
        "archetypes": ctx.files.archetypes,
        "assets": ctx.files.assets,
        "content": ctx.files.content,
        "data": ctx.files.data,
        "i18n": ctx.files.i18n,
        "images": ctx.files.images,
        "layouts": ctx.files.layouts,
        "static": ctx.files.static,
        "config": ctx.files.config_dir,
    }.items():
        hugo_inputs += copy_to_dir(ctx, srcs, name)

    # Copy the theme
    if ctx.attr.theme:
        theme = ctx.attr.theme.hugo_theme
        hugo_args += ["--theme", theme.name]
        for i in theme.files.to_list():
            path_list = i.short_path.split("/")
            if i.short_path.startswith("../"):
                o_filename = "/".join(["themes", theme.name] + path_list[2:])
            elif i.short_path[len(theme.path):].startswith("/themes"): # check if themes is the first dir after theme path
                indx = path_list.index("themes")
                o_filename = "/".join(["themes", theme.name] + path_list[indx+2:])
            else:
                o_filename = "/".join(["themes", theme.name, i.short_path[len(theme.path):]])
            o = ctx.actions.declare_file(o_filename)
            ctx.actions.run_shell(
                inputs = [i],
                outputs = [o],
                command = 'cp -r -L "$1" "$2"',
                arguments = [i.path, o.path],
            )
            hugo_inputs.append(o)

    # Prepare hugo command
    hugo_args += [
        "--destination",
        ctx.label.name,
    ]

    if ctx.attr.quiet:
        hugo_args.append("--quiet")
    if ctx.attr.verbose:
        hugo_args.append("--verbose")
    if ctx.attr.base_url:
        hugo_args += ["--baseURL", ctx.attr.base_url]
    if ctx.attr.build_drafts:
        hugo_args += ["--buildDrafts"]

    ctx.actions.run(
        mnemonic = "GoHugo",
        progress_message = "Generating hugo site",
        executable = hugo,
        arguments = hugo_args,
        inputs = hugo_inputs,
        outputs = hugo_outputs,
        tools = [hugo],
        execution_requirements = {
            "no-sandbox": "1",
        }, 
    )

    files = depset([hugo_outputdir])
    runfiles = ctx.runfiles(files = [hugo_outputdir] + hugo_inputs)

    return [DefaultInfo(
        files = files,
        runfiles = runfiles,
    )]

hugo_site = rule(
    attrs = {
        # Hugo config file
        "config": attr.label(
            allow_single_file = [
                ".toml",
                ".yaml",
                ".yml",
                ".json",
            ],
        ),
        # For use of config directories
        "config_dir": attr.label_list(
            allow_files = True,
        ),
        # Files to be included in the content/ subdir
        "content": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        # Files to be included in the archetypes/ subdir
        "archetypes": attr.label_list(
            allow_files = True,
        ),
        # Files to be included in the static/ subdir
        "static": attr.label_list(
            allow_files = True,
        ),
        # Files to be included in the images/ subdir
        "images": attr.label_list(
            allow_files = True,
        ),
        # Files to be included in the layouts/ subdir
        "layouts": attr.label_list(
            allow_files = True,
        ),
        # Files to be included in the assets/ subdir
        "assets": attr.label_list(
            allow_files = True,
        ),
        # Files to be included in the data/ subdir
        "data": attr.label_list(
            allow_files = True,
        ),
        # Files to be included in the i18n/ subdir
        "i18n": attr.label_list(
            allow_files = True,
        ),        
        # The hugo executable
        "hugo": attr.label(
            default = "@hugo//:hugo",
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        # Optionally set the base_url as a hugo argument
        "base_url": attr.string(),
        "theme": attr.label(
            providers = ["hugo_theme"],
        ),
        # Emit quietly
        "quiet": attr.bool(
            default = True,
        ),
        # Emit verbose
        "verbose": attr.bool(
            default = False,
        ),
        # Build content marked as draft
        "build_drafts": attr.bool(
            default = False,
        ),
    },
    implementation = _hugo_site_impl,
)

_SERVE_SCRIPT_PREFIX = """#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

trap exit_gracefully SIGINT
function exit_gracefully() {
    exit 0;
}

"""
_SERVE_SCRIPT_TEMPLATE = """{hugo_bin} serve -s $DIR {args}"""

def _hugo_serve_impl(ctx):
    """ This is a long running process used for development"""
    hugo = ctx.executable.hugo
    hugo_outfile = ctx.actions.declare_file("{}.out".format(ctx.label.name))
    hugo_outputs = [hugo_outfile]
    hugo_args = []

    if ctx.attr.quiet:
        hugo_args.append("--quiet")
    if ctx.attr.verbose:
        hugo_args.append("--logLevel")
        hugo_args.append("info")
    if ctx.attr.disable_fast_render:
        hugo_args.append("--disableFastRender")

    executable_path = "./" + ctx.attr.hugo.files_to_run.executable.short_path

    runfiles = ctx.runfiles()
    runfiles = runfiles.merge(ctx.runfiles(files=[ctx.attr.hugo.files_to_run.executable]))

    for dep in ctx.attr.dep:
        runfiles = runfiles.merge(dep.default_runfiles).merge(dep.data_runfiles).merge(ctx.runfiles(files=dep.files.to_list()))


    script = ctx.actions.declare_file("{}-serve".format(ctx.label.name))
    script_content = _SERVE_SCRIPT_PREFIX + _SERVE_SCRIPT_TEMPLATE.format(
        hugo_bin=executable_path,
        args=" ".join(hugo_args),
    )
    ctx.actions.write(output=script, content=script_content, is_executable=True)

    ctx.actions.run_shell(
        mnemonic = "GoHugoServe",
        tools = [script, hugo],
        command = script.path,
        outputs = hugo_outputs,
        execution_requirements={
            "no-sandbox": "1",
        },
    )

    return [DefaultInfo(executable=script, runfiles=runfiles)]


hugo_serve = rule(
    attrs = {
        # The hugo executable
        "hugo": attr.label(
            default = "@hugo//:hugo",
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
        "dep": attr.label_list(
            mandatory=True,
        ),
        # Disable fast render
        "disable_fast_render": attr.bool(
            default = False,
        ),
        # Emit quietly
        "quiet": attr.bool(
            default = True,
        ),
        # Emit verbose
        "verbose": attr.bool(
            default = False,
        ),
    },
    implementation = _hugo_serve_impl,
    executable = True,
)
