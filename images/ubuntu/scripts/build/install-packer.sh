#!/bin/bash -e
################################################################################
##  File:  install-packer.sh
##  Desc:  Install packer
################################################################################

# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

# Set architecture-specific variables using a case statement for clarity
case "$ARCH" in
    "x86_64")
        package_arch="amd64"
        ;;
    "s390x")
        echo "Packer is not officially available for the s390x architecture."
        exit 0
        ;;
    "ppc64le" | *)
        package_arch="$ARCH"
        ;;
esac

# Install Packer for amd64
download_url=$(curl -fsSL https://api.releases.hashicorp.com/v1/releases/packer/latest | jq -r --arg arch "$package_arch" '.builds[] | select((.arch==$arch) and (.os=="linux")).url')
archive_path=$(download_with_retry "$download_url")
unzip -o -qq "$archive_path" -d /usr/local/bin
