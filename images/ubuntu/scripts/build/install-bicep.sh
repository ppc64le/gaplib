#!/bin/bash -e
################################################################################
##  File:  install-bicep.sh
##  Desc:  Install bicep cli
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

# Install Bicep CLI
download_url=$(resolve_github_release_asset_url "Azure/bicep" "endswith(\"bicep-linux-${package_arch}\")" "latest")
bicep_binary_path=$(download_with_retry "${download_url}")

# Mark it as executable
install "$bicep_binary_path" /usr/local/bin/bicep


