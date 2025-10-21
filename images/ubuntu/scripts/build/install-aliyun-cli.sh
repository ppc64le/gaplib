#!/bin/bash -e
################################################################################
##  File:  install-aliyun-cli.sh
##  Desc:  Install Alibaba Cloud CLI
##  Supply chain security: Alibaba Cloud CLI - checksum validation
################################################################################

# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/os.sh
source "$HELPER_SCRIPTS"/install.sh

# Set architecture-specific variables using a case statement for clarity
case "$ARCH" in
    "ppc64le" | "s390x")
        echo "No actions defined for $ARCH architecture."
        exit 0
        ;;
    "x86_64")
        package_arch="amd64"
        ;;
    *)
        package_arch="$ARCH"
        ;;
esac

# Install Alibaba Cloud CLI
    
download_url=$(resolve_github_release_asset_url "aliyun/aliyun-cli" "contains(\"aliyun-cli-linux\") and endswith(\"${package_arch}.tgz\")" "latest")
hash_url="https://github.com/aliyun/aliyun-cli/releases/latest/download/SHASUMS256.txt"
    
archive_path=$(download_with_retry "$download_url")
    
# Supply chain security - Alibaba Cloud CLI
external_hash=$(get_checksum_from_url "$hash_url" "aliyun-cli-linux.*${package_arch}.tgz" "SHA256")
    
use_checksum_comparison "$archive_path" "$external_hash"
    
tar xzf "$archive_path"
mv aliyun /usr/local/bin