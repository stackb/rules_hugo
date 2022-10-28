# Copyright 2022 Google LLC
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@build_stack_rules_hugo//hugo:rules.bzl", "hugo_site", "hugo_theme", "hugo_serve")

hugo_theme(
    name = "hugo_theme_geekdoc",
    theme_name = "hugo-geekdoc",
    srcs = [
        "@com_github_thegeeklab_hugo_geekdoc//:files",
    ],
)

hugo_site(
    name = "site_complex",
    config_dir = glob(["config/**"]),
    content = glob(["content/**"]),
    data = glob(["data/**"]),
    quiet = False,
    theme = ":hugo_theme_geekdoc",
    verbose = True,
)

# Run local development server
hugo_serve(
    name = "serve",
    dep = [":site_complex"],
)
