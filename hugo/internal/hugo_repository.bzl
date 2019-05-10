load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

HUGO_BUILD_FILE = """    
package(default_visibility = ["//visibility:public"])
exports_files( ["hugo"] )
"""

def _hugo_repository_impl(repository_ctx):
    hugo = "hugo"
    if repository_ctx.attr.extended:
        hugo = "hugo_extended"

    os_arch = repository_ctx.attr.os_arch

    os_name = repository_ctx.os.name.lower()
    if os_name.startswith("mac os"):
        os_arch = "macOS-64bit"
    elif os_name.find("windows") != -1:
        os_arch = "Windows-64bit"
    else:
        os_arch = "Linux-64bit"
    
    url = "https://github.com/gohugoio/hugo/releases/download/v{version}/{hugo}_{version}_{os_arch}.tar.gz".format(
        hugo = hugo,
        os_arch = os_arch,
        version = repository_ctx.attr.version,
    )

    repository_ctx.download_and_extract(
        url = url,
        sha256 = repository_ctx.attr.sha256,
    )

    repository_ctx.file("BUILD.bazel", HUGO_BUILD_FILE)

hugo_repository = repository_rule(
    _hugo_repository_impl,
    attrs = {
        "version": attr.string(
            default = "0.55.5",
            doc = "The hugo version to use",
        ),
        "sha256": attr.string(
            doc = "The sha256 value for the binary",
        ),
        "os_arch": attr.string(
            doc = "The os arch value. If empty, autodetect it",
        ),
        "extended": attr.bool(
            doc = "Use extended hugo version",
        ),
    },
)
