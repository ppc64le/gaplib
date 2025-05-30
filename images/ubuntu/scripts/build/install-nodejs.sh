#!/bin/bash -e
################################################################################
##  File:  install-nodejs.sh
##  Desc:  Install Node.js LTS and related tooling (Gulp, Grunt)
################################################################################
# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

# Install default Node.js
default_version=$(get_toolset_value '.node.default')
curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o ~/n
bash ~/n $default_version

if [[ "$ARCH" == "ppc64le" || "$ARCH" == "s390x" ]]; then
    npm install -g grunt gulp n typescript newman vercel webpack webpack-cli yarn
else
    # Install node modules
    node_modules=$(get_toolset_value '.node_modules[].name')
    npm install -g $node_modules
fi

echo "Creating the symlink for [now] command to vercel CLI"
ln -s /usr/local/bin/vercel /usr/local/bin/now

# fix global modules installation as regular user
# related issue https://github.com/actions/runner-images/issues/3727
sudo chmod -R 777 /usr/local/lib/node_modules 
sudo chmod -R 777 /usr/local/bin

rm -rf ~/n
