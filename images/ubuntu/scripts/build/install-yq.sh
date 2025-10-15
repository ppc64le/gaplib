#!/bin/bash -e
################################################################################
##  File:  install-yq.sh
##  Desc:  Install yq - a command-line YAML, JSON and XML processor
##  Supply chain security: yq - checksum validation
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

# Download yq for package_arch
yq_url=$(resolve_github_release_asset_url "mikefarah/yq" "endswith(\"yq_linux_${package_arch}\")" "latest")
binary_path=$(download_with_retry "${yq_url}")

# Supply chain security - yq
# hash_url=$(resolve_github_release_asset_url "mikefarah/yq" "endswith(\"checksums\")" "latest")
# external_hash=$(get_checksum_from_url "${hash_url}" "yq_linux_${package_arch}" "SHA256" "true" " " "19")
# use_checksum_comparison "$binary_path" "$external_hash"

# Install yq
install "$binary_path" /usr/bin/yq