#!/bin/bash -e
################################################################################
##  File:  install-google-cloud-cli.sh
##  Desc:  Install the Google Cloud CLI
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

REPO_URL="https://packages.cloud.google.com/apt"

# Install the Google Cloud CLI
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] $REPO_URL cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
wget -qO- https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor > /usr/share/keyrings/cloud.google.gpg
update_dpkgs
install_dpkgs google-cloud-cli

# remove apt
rm /etc/apt/sources.list.d/google-cloud-sdk.list
rm /usr/share/keyrings/cloud.google.gpg

# add repo to the apt-sources.txt
echo "google-cloud-sdk $REPO_URL" >> "$HELPER_SCRIPTS"/apt-sources.txt
