#!/bin/bash -e
################################################################################
##  File:  install-pulumi.sh
##  Desc:  Install Pulumi
##  Supply chain security: Pulumi - checksum validation
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
    "x86_64")
        package_arch="x64"
        ;;
    *)
        package_arch="$ARCH"
        ;;
esac

# Dowload Pulumi
version=$(curl -fsSL "https://www.pulumi.com/latest-version")
download_url="https://get.pulumi.com/releases/sdk/pulumi-v${version}-linux-${package_arch}.tar.gz"
archive_path=$(download_with_retry "$download_url")

# Supply chain security - Pulumi
external_hash=$(get_checksum_from_url "https://github.com/pulumi/pulumi/releases/download/v${version}/SHA512SUMS" "linux-${package_arch}.tar.gz" "SHA512")
use_checksum_comparison "$archive_path" "$external_hash" "512"

# Unzipping Pulumi
tar --strip=1 -xf "$archive_path" -C /usr/local/bin