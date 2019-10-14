def _hugo_theme_impl(ctx):
    return struct(
        hugo_theme = struct(
            name = ctx.attr.theme_name or ctx.label.name,
            path = ctx.label.package,
            files = depset(ctx.files.srcs),
        ),
    )

hugo_theme = rule(
    attrs = {
        "theme_name": attr.string(
        ),
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = True,
        ),
    },
    implementation = _hugo_theme_impl,
)
