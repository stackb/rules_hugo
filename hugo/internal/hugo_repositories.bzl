HUGO_BUILD_FILE = """    
package(default_visibility = ["//visibility:public"])
exports_files( ["hugo"] )
"""

def hugo_repositories(hugo_version = "0.31.1",
                      hugo_os_arch = "Linux-64bit",
                      hugo_sha256 = None,
):
    hugo_url = "https://github.com/gohugoio/hugo/releases/download/v{version}/hugo_{version}_{os_arch}.tar.gz".format(
        version = hugo_version,
        os_arch = hugo_os_arch,
    )

    native.new_http_archive(
        name = "hugo",
        url = hugo_url,
        build_file_content = HUGO_BUILD_FILE,
        sha_256 = hugo_sha256,
    )

    
