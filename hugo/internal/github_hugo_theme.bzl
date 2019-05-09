load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

DEFAULT_BUILD_FILE = """
filegroup(
    name = "files",
    srcs = glob(["**/*"]), 
    visibility = ["//visibility:public"],
)
"""

def github_hugo_theme(name, owner, repo, commit, **kwargs):
    url = "https://github.com/{owner}/{repo}/archive/{commit}.zip".format(
        owner = owner,
        repo = repo,
        commit = commit,
    )
    strip_prefix = "{repo}-{commit}".format(
        repo = repo,
        commit = commit,
    )
    if "build_file" in kwargs or "build_file_content" in kwargs:
        http_archive(
            name = name,
            url = url,
            strip_prefix = strip_prefix,
            **kwargs
        )
    else:
        http_archive(
            name = name,
            url = url,
            strip_prefix = strip_prefix,
            build_file_content = DEFAULT_BUILD_FILE,
            **kwargs
        )
