load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

DEFAULT_HUGO_VERSION = "0.31.1"

HUGO_BUILD_FILE = """    
package(default_visibility = ["//visibility:public"])
exports_files( ["hugo"] )
"""

HUGO_SHA256_SUMS = {
    ("0.31.1", "Linux-64bit"): "2ec6fd0493fa246a5747b0f1875d94affaaa30f11715f26abcbe1bc91c940716",
    ("0.48", "Linux-64bit"): "1d26dab6445fc40aa23ecd8d49cd6fdbe8b06d722907bc97b3d32e385555b2df",
    ("0.49", "Linux-64bit"): "768296178bb3ca5daaf39d897a2505f91e0224ca48a41dc0d1d73120859c4b1f",
    ("0.49.1", "Linux-64bit"): "e037fc8476b388a438f037e05a98ea9f4694e9729d3b4dca052474f10fbfbbc8",
    ("0.49.2", "Linux-64bit"): "74bcca80f549a1b66ec8a5264a9308ef7056b7bd31214f56dac05ffb9dfd32b3",
    ("0.50", "Linux-64bit"): "5e04ffe2e7cb0c3e1c364faca37a7f2e3e94db3d36d94ee290e3a3e1557dfc9a",
    ("0.51", "Linux-64bit"): "96579d81ea38e7ad5bc0bb675eff2be0d86d28e284cb43aa1893f627d07d4bda",
    ("0.52", "Linux-64bit"): "b4d1fe91023e3fe7e92953af12e08344d66ab10a46feb9cbcffbab2b0c14ba44",
    ("0.53", "Linux-64bit"): "0e4424c90ce5c7a0c0f7ad24a558dd0c2f1500256023f6e3c0004f57a20ee119",
}

def hugo_repositories(hugo_version = DEFAULT_HUGO_VERSION,
                      hugo_os_arch = "Linux-64bit",
                      hugo_sha256 = None,
):
    hugo_url = "https://github.com/gohugoio/hugo/releases/download/v{version}/hugo_{version}_{os_arch}.tar.gz".format(
        version = hugo_version,
        os_arch = hugo_os_arch,
    )

    if not hugo_sha256:
        hugo_sha256 = HUGO_SHA256_SUMS.get((hugo_version, hugo_os_arch), None)

    if not hugo_sha256:
        print("WARNING: SHA256 checksum not provided (hugo_sha256 argument) " + \
              "and ({version}, {os_arch}) not found in HUGO_SHA256_SUMS.".format(
                  version = hugo_version,
                  os_arch = hugo_os_arch,
              ))

    http_archive(
        name = "hugo",
        url = hugo_url,
        build_file_content = HUGO_BUILD_FILE,
        sha256 = hugo_sha256,
    )
