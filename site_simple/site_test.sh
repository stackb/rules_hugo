set -euxo pipefail

find .

# Make a few assertions about the generated site
test -f site_simple/site_simple/index.html
test -f site_simple/site_simple/index.xml
