#!/bin/bash -e
################################################################################
##  File:  install-runner-package.sh
##  Desc:  Download and Install runner package
################################################################################

# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

SRC=$(readlink -f "${BASH_SOURCE[0]}")
DIR=$(dirname "${SRC}")

# Set architecture-specific variables using a case statement for clarity
case "$ARCH" in
    "ppc64le" | "s390x")
        source "${DIR}/configure-runner.sh"
        exit 0
        ;;
    "x86_64")
        package_arch="x64"
        ;;
    *)
        package_arch="$ARCH"
        ;;
esac

download_url=$(resolve_github_release_asset_url "actions/runner" "test(\"actions-runner-linux-${package_arch}-[0-9]+\\\\.[0-9]{3}\\\\.[0-9]+\\\\.tar\\\\.gz$\")" "latest")
archive_name="${download_url##*/}"
archive_path=$(download_with_retry "$download_url")

mkdir -p /opt/runner-cache
mv "$archive_path" "/opt/runner-cache/$archive_name"