# `rules_hugo`

<table><tr>
<td><img src="https://bazel.build/images/bazel-icon.svg" height="120"/></td>
<td><img src="https://raw.githubusercontent.com/gohugoio/hugoDocs/master/static/img/hugo-logo.png" height="120"/></td>
</tr><tr>
<td>Rules</td>
<td>Hugo</td>
</tr></table>

[Bazel](https://bazel.build) rules for building static websites with [Hugo](https://gohugo.io).

## Repository Rules

|               Name   |  Description |
| -------------------: | :----------- |
| [hugo_repositories](#hugo_repositories) | Load dependencies for this repo. |
| [github_hugo_theme](#github_hugo_theme) | Load a hugo theme from github. |

## Build Rules

|               Name   |  Description |
| -------------------: | :----------- |
| [hugo_site](#hugo_site) | Declare a hugo site. |
| [hugo_theme](#hugo_theme) | Declare a hugo theme. |

## Usage

### Add rules_hugo to your WORKSPACE and add a theme from github

```python
# Update these to latest
RULES_HUGO_COMMIT = "..."
RULES_HUGO_SHA256 = "..."

http_archive(
    name = "build_stack_rules_hugo",
    url = "https://github.com/stackb/rules_hugo/archive/%s.zip" % RULES_HUGO_COMMIT,
    sha256 = RULES_HUGO_SHA256,
    strip_prefix = "rules_hugo-%s" % RULES_HUGO_COMMIT
)

load("@build_stack_rules_hugo//hugo:rules.bzl", "hugo_repositories", "github_hugo_theme")

#
# Load hugo binary itself
#
hugo_repositories()

#
# This makes a filegroup target "@com_github_yihui_hugo_xmin//:files"
# available to your build files
#
github_hugo_theme(
    name = "com_github_yihui_hugo_xmin",
    owner = "yihui",
    repo = "hugo-xmin",
    commit = "c14ca049d0dd60386264ea68c91d8495809cc4c6",
)
```

### Declare a hugo_site

```python
load("@build_stack_rules_hugo//hugo:rules.bzl", "hugo_site", "hugo_theme")

# Declare a theme 'xmin'.  In this case the `name` and
# `theme_name` are identical, so the `theme_name` could be omitted in this case.
hugo_theme(
    name = "xmin",
    theme_name = "xmin",
    srcs = [
        "@com_github_yihui_hugo_xmin//:files",
    ],
)

# Declare a site. Config file is required.
hugo_site(
    name = "basic",
    config = "config.toml",
    content = [
        "_index.md",
        "about.md",
    ],
    quiet = False,
    theme = ":xmin",
)

```

### Build the site

Build the `hugo_site` target emits a `%{name}_site.zip` file
containing all the files in the site.

```sh
$ bazel build :basic
Target //:basic up-to-date:
  bazel-bin/basic_site.zip
```

## End

See source code for details about additional rule attributes / parameters.
