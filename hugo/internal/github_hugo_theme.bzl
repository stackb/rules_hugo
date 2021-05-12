load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

DEFAULT_BUILD_FILE = """
filegroup(
    name = "files",
    srcs = glob(["**/*"]), 
    visibility = ["//visibility:public"],
)
"""

DEFAULT_GITHUB_HOST = "github.com"

def github_hugo_theme(name, owner, repo, commit, github_host=DEFAULT_GITHUB_HOST, **kwargs):

    url = "https://{github_host}/{owner}/{repo}/archive/{commit}.zip".format(
        owner = owner,
        repo = repo,
        commit = commit,
        github_host = github_host,
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
