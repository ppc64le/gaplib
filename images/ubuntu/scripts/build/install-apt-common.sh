#!/bin/bash -e
################################################################################
##  File:  install-apt-common.sh
##  Desc:  Install basic command line utilities and dev packages
################################################################################
# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

common_packages=$(get_toolset_value .apt.common_packages[])
cmd_packages=$(get_toolset_value .apt.cmd_packages[])

for package in $common_packages $cmd_packages; do
    echo "Install $package"
    install_dpkgs --no-install-recommends $package
done
