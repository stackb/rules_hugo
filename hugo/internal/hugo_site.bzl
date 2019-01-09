
def copy_to_dir(ctx, srcs, dirname):
    outs = []
    for i in srcs:
        o = ctx.actions.declare_file(dirname + "/" + i.basename)
        ctx.action(
            inputs = [i],
            outputs = [o],
            command = 'cp "$1" "$2"',
            arguments = [i.path, o.path]
        )
        outs.append(o)
    return outs


def _hugo_site_impl(ctx):
    zip_file = ctx.outputs.zip_file
    hugo = ctx.executable.hugo
    hugo_inputs = [hugo]
    hugo_outputs = [zip_file]
    hugo_args = []

    # Copy the config file into place
    config_file = ctx.actions.declare_file(ctx.file.config.basename)
    ctx.action(
        inputs = [ctx.file.config],
        outputs = [config_file],
        command = 'cp "$1" "$2"',
        arguments = [ctx.file.config.path, config_file.path]
    )
    hugo_inputs.append(config_file)

    # Copy all the files over
    content_files = copy_to_dir(ctx, ctx.files.content, "content")
    static_files = copy_to_dir(ctx, ctx.files.static, "static")
    image_files = copy_to_dir(ctx, ctx.files.images, "images")
    layout_files = copy_to_dir(ctx, ctx.files.layouts, "layouts")
    data_files = copy_to_dir(ctx, ctx.files.data, "data")
    hugo_inputs += content_files + static_files + image_files + layout_files + data_files

    # Copy the theme
    if ctx.attr.theme:
        theme = ctx.attr.theme.hugo_theme
        hugo_args += ["--theme", theme.name]
        for i in theme.files:
            if i.short_path.startswith("../"):
                o_filename = "/".join(["themes", theme.name] + i.short_path.split("/")[2:])
            else:
                o_filename = "/".join(["themes", theme.name, i.short_path])
            o = ctx.actions.declare_file(o_filename)
            ctx.action(
                inputs = [i],
                outputs = [o],
                command = 'cp "$1" "$2"',
                arguments = [i.path, o.path],
            )
            hugo_inputs.append(o)

    # Prepare hugo command
    hugo_args += [
        "--config", config_file.path,
        "--contentDir", "/".join([config_file.dirname, "content"]),
        "--themesDir", "/".join([config_file.dirname, "themes"]),
        "--layoutDir", "/".join([config_file.dirname, "layouts"]),
        "--destination", "/".join([config_file.dirname, ctx.label.name]),
    ]

    if ctx.attr.quiet:
        hugo_args.append("--quiet")
    if ctx.attr.verbose:
        hugo_args.append("--verbose")
    if ctx.attr.base_url:
        hugo_args.append("--baseURL", ctx.attr.base_url)
    hugo_command = " ".join([hugo.path] + hugo_args)

    # Prepare zip command
    zip_args = ["zip", "-r", ctx.outputs.zip_file.path]
    if ctx.attr.quiet:
        zip_args.insert(1, "--quiet")
    zip_args.append(zip_file.dirname + "/" + ctx.label.name)
    zip_command = " ".join(zip_args)

    # Generate site and zip up the publishDir
    ctx.actions.run_shell(
        mnemonic = "GoHugo",
        progress_message = "Generating hugo site",
        command = " && ".join([hugo_command, zip_command]),
        inputs = hugo_inputs,
        outputs = hugo_outputs,
        execution_requirements = {
            "no-sandbox": "1",
        },
    )

    # Return files and 'hugo_site' provider
    return struct(
        files = depset(hugo_outputs),
        hugo_site = struct(
            name = ctx.label.name,
            content = content_files,
            static = static_files,
            data = data_files,
            config = config_file,
            theme = ctx.attr.theme,
            archive = zip_file,
        ),
    )

hugo_site = rule(
    implementation = _hugo_site_impl,
    attrs = {
        # Hugo config file
        "config": attr.label(
            allow_files = FileType([".toml", ".yaml", ".json"]),
            single_file = True,
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
    outputs = {
        "zip_file": "%{name}_site.zip",
    }
)

