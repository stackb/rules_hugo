workspace(name = "build_stack_rules_hugo")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

load("@build_stack_rules_hugo//hugo:rules.bzl", "github_hugo_theme", "hugo_repository")

hugo_repository(
    name = "hugo",
    extended = True,
)

github_hugo_theme(
    name = "com_github_alex_shpak_hugo_book",
    commit = "07048f7bf5097435a05c1e8b77241b0e478023c2",  # June 3, 2019
    owner = "alex-shpak",
    repo = "hugo-book",
)
