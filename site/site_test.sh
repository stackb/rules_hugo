set -euxo pipefail

find .

# Make a few assertions about the generated site
test -f site/site/index.html
test -f site/site/index.xml
