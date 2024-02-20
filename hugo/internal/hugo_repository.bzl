load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

HUGO_BUILD_FILE = """
package(default_visibility = ["//visibility:public"])
exports_files(["hugo"])
"""

def _hugo_repository_impl(repository_ctx):
    hugo = "hugo"
    if repository_ctx.attr.extended:
        hugo = "hugo_extended"

    os_arch = repository_ctx.attr.os_arch
    archive_suffix = "tar.gz"
    os_name = repository_ctx.os.name.lower()
    if os_arch == "":
        if os_name.startswith("mac os"):
            os_arch = "darwin-universal"
        elif os_name.find("windows") != -1:
            os_arch = "windows-amd64"
            archive_suffix = "zip"
        else:
            os_arch = "Linux-64bit"

    url = "https://github.com/gohugoio/hugo/releases/download/v{version}/{hugo}_{version}_{os_arch}.{archive_suffix}".format(
        hugo = hugo,
        os_arch = os_arch,
        archive_suffix = archive_suffix,
        version = repository_ctx.attr.version,
    )

    repository_ctx.download_and_extract(
        url = url,
        sha256 = repository_ctx.attr.sha256,
    )

    # On Windows, the Hugo binary is named `hugo.exe`. We must symlink to
    # `hugo` so that there is a consistent location for the binary across
    # platforms.
    if os_name.find("windows") != -1:
        repository_ctx.symlink("hugo.exe", "hugo")

    repository_ctx.file("BUILD.bazel", HUGO_BUILD_FILE)

hugo_repository = repository_rule(
    _hugo_repository_impl,
    attrs = {
        "version": attr.string(
            default = "0.122.0",
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
