#!/bin/bash -e
################################################################################
##  File:  install-oras-cli.sh
##  Desc:  Install ORAS CLI
##  Supply chain security: ORAS CLI - checksum validation
################################################################################

# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

# Set architecture-specific variables using a case statement for clarity
case "$ARCH" in
    "x86_64")
        package_arch="amd64"
        ;;
    "ppc64le" | "s390x" | *)
        package_arch="$ARCH"
        ;;
esac

# Determine latest ORAS CLI version
download_url=$(resolve_github_release_asset_url "oras-project/oras" "endswith(\"linux_${package_arch}.tar.gz\")" "latest")

# Download ORAS CLI
archive_path=$(download_with_retry "$download_url")

# Supply chain security - ORAS CLI
hash_url=$(resolve_github_release_asset_url "oras-project/oras" "endswith(\"checksums.txt\")" "latest")
external_hash=$(get_checksum_from_url "${hash_url}" "linux_${package_arch}.tar.gz" "SHA256")
use_checksum_comparison "$archive_path" "${external_hash}"

# Unzip ORAS CLI
tar xzf "$archive_path" -C /usr/local/bin oras

