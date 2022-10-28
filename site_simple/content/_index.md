---
title: Introduction
type: docs
---

# Bazel Rules for Hugo Static Site Generator

<table><tr>
<td><img src="https://bazel.build/images/bazel-icon.svg" height="120"/></td>
<td><img src="https://raw.githubusercontent.com/gohugoio/hugoDocs/master/static/img/hugo-logo.png" height="120"/></td>
</tr><tr>
<td>Rules</td>
<td>Hugo</td>
</tr></table>

## Add Workspace Dependencies

Declare a dependency on `build_stack_rules_hugo` in your `WORKSPACE`:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_stack_rules_hugo",
    urls = ["https://github.com/stackb/rules_hugo/archive/6bca4c2786a54d7d7acfa76cd51b0a6370bd91c4.tar.gz"],
    strip_prefix = "rules_hugo-6bca4c2786a54d7d7acfa76cd51b0a6370bd91c4",
    sha256 = "7d2fe8b2ba4e6e662c79c1503890c2eb82d5717a411bb6fd805269758da40c9a",
)
```

Declare a dependency on the hugo binary as well as a theme in your `WORKSPACE`:

```python
load("@build_stack_rules_hugo//hugo:rules.bzl", "github_hugo_theme", "hugo_repository")

hugo_repository(
    name = "hugo",
    extended = True,
)

github_hugo_theme(
    name = "com_github_alex_shpak_hugo_book",
    commit = "07048f7bf5097435a05c1e8b77241b0e478023c2",
    owner = "alex-shpak",
    repo = "hugo-book",
)
```

## Add Theme Files

Copy the site template files into your repository.  Typically themes include an
`exampleSite`, so one way to do this is:

```sh
$ bazel fetch @com_github_alex_shpak_hugo_book//:files
$ cp $(bazel info output_base)/external/com_github_alex_shpak_hugo_book/exampleSite/ ./site
```

## Build Rules

Create a build file for the site:

```sh
$ touch site/BUILD.bazel
```

Having the following rules:

```python
load("@build_stack_rules_hugo//hugo:rules.bzl", "hugo_site", "hugo_theme")

hugo_theme(
    name = "book",
    srcs = [
        "@com_github_alex_shpak_hugo_book//:files",
    ],
)

hugo_site(
    name = "site",
    config = "config.yaml",
    content = glob(["content/**"]),
    static = glob(["static/**"]),
    layouts = glob(["layouts/**"]),
    theme = ":book",
)
```

## Generate

To build the site:

```sh
$ bazel build //site
```

Locally serve site:

```sh
$ (cd $(shell bazel info bazel-bin)/site/site && python -m SimpleHTTPServer 7070)
```

Create a tarball:

```sh
$ tar -cvf bazel-out/site.tar -C $(shell bazel info bazel-bin)/site/site .
```

## End

Have fun!
