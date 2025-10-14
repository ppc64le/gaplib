#!/bin/bash -e
################################################################################
##  File:  install-rlang.sh
##  Desc:  Install R
################################################################################
# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

# Set architecture-specific variables using a case statement for clarity
case "$ARCH" in
    "ppc64le" | "s390x")
        echo "No actions defined for $ARCH architecture."
        exit 0
        ;;
    *)
        ;;
esac

# install R
os_label=$(lsb_release -cs)

wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | gpg --dearmor > /usr/share/keyrings/rlang.gpg
echo "deb [signed-by=/usr/share/keyrings/rlang.gpg] https://cloud.r-project.org/bin/linux/ubuntu $os_label-cran40/" > /etc/apt/sources.list.d/rlang.list

update_dpkgs
install_dpkgs r-base

rm /etc/apt/sources.list.d/rlang.list
rm /usr/share/keyrings/rlang.gpg

