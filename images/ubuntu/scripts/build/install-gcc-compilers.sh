#!/bin/bash -e
################################################################################
##  File:  install-gcc-compilers.sh
##  Desc:  Install GNU C++ compilers
################################################################################

# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

versions=$(get_toolset_value '.gcc.versions[]')

# shellcheck disable=SC2048
for version in ${versions[*]}; do
    echo "Installing $version..."
    install_dpkgs "$version"
done
