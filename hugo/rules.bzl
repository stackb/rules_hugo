load("//hugo:internal/hugo_repository.bzl", _hugo_repository = "hugo_repository")
load("//hugo:internal/hugo_site.bzl", _hugo_site = "hugo_site", _hugo_serve = "hugo_serve")
load("//hugo:internal/hugo_theme.bzl", _hugo_theme = "hugo_theme")
load("//hugo:internal/github_hugo_theme.bzl", _github_hugo_theme = "github_hugo_theme")

hugo_repository = _hugo_repository

hugo_serve = _hugo_serve

hugo_site = _hugo_site

hugo_theme = _hugo_theme

github_hugo_theme = _github_hugo_theme
