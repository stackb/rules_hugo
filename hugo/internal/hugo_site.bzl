def relative_path(src, dirname):
    """Given a src File and a directory it's under, return the relative path.

    For example,
    Input:
       src: File(path/to/site/content/docs/example1.md)
       dirname: string("content")
    Returns:
       "content/docs/example1.md"
    """

    # Find the last path segment that matches the given dirname, and return that
    # substring.
    i = src.short_path.rfind("/%s/" % dirname)
    if i == -1:
        fail("failed to get relative path: couldn't find %s in %s" % (dirname, src.short_path))
    return src.short_path[i + 1:]

def copy_to_dir(ctx, srcs, dirname):
    outs = []
    for i in srcs:
        o = ctx.actions.declare_file(relative_path(i, dirname))
        ctx.actions.run_shell(
            inputs = [i],
            outputs = [o],
            command = 'cp "$1" "$2"',
            arguments = [i.path, o.path],
        )
        outs.append(o)
    return outs

def _hugo_site_impl(ctx):
    hugo = ctx.executable.hugo
    hugo_inputs = []
    hugo_outputdir = ctx.actions.declare_directory(ctx.label.name)
    hugo_outputs = [hugo_outputdir]
    hugo_args = []

    # Copy the config file into place
    config_file = ctx.actions.declare_file(ctx.file.config.basename)
    ctx.actions.run_shell(
        inputs = [ctx.file.config],
        outputs = [config_file],
        command = 'cp "$1" "$2"',
        arguments = [ctx.file.config.path, config_file.path],
    )
    hugo_inputs.append(config_file)

    # Copy all the files over
    content_files = copy_to_dir(ctx, ctx.files.content, "content")
    static_files = copy_to_dir(ctx, ctx.files.static, "static")
    image_files = copy_to_dir(ctx, ctx.files.images, "images")
    layout_files = copy_to_dir(ctx, ctx.files.layouts, "layouts")
    data_files = copy_to_dir(ctx, ctx.files.data, "data")
    asset_files = copy_to_dir(ctx, ctx.files.assets, "assets")
    hugo_inputs += content_files + static_files + image_files + layout_files + asset_files + data_files

    # Copy the theme
    if ctx.attr.theme:
        theme = ctx.attr.theme.hugo_theme
        hugo_args += ["--theme", theme.name]
        for i in theme.files.to_list():
            if i.short_path.startswith("../"):
                o_filename = "/".join(["themes", theme.name] + i.short_path.split("/")[2:])
            else:
                o_filename = "/".join(["themes", theme.name, i.short_path[len(theme.path):]])
            o = ctx.actions.declare_file(o_filename)
            ctx.actions.run_shell(
                inputs = [i],
                outputs = [o],
                command = 'cp "$1" "$2"',
                arguments = [i.path, o.path],
            )
            hugo_inputs.append(o)

    # Prepare hugo command
    hugo_args += [
        "--source",
        config_file.dirname,
        "--destination",
        ctx.label.name,
    ]

    if ctx.attr.quiet:
        hugo_args.append("--quiet")
    if ctx.attr.verbose:
        hugo_args.append("--verbose")
    if ctx.attr.base_url:
        hugo_args += ["--baseURL", ctx.attr.base_url]

    ctx.actions.run(
        mnemonic = "GoHugo",
        progress_message = "Generating hugo site",
        executable = hugo,
        arguments = hugo_args,
        inputs = hugo_inputs,
        outputs = hugo_outputs,
        tools = [hugo],
    )

    return [DefaultInfo(files = depset([hugo_outputdir]))]

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
            mandatory = True,
        ),
        # Files to be included in the content/ subdir
        "content": attr.label_list(
            allow_files = True,
            mandatory = True,
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
    },
    implementation = _hugo_site_impl,
)
