#!/bin/bash -e
################################################################################
##  File:  install-github-cli.sh
##  Desc:  Install GitHub CLI
##         Must be run as non-root user after homebrew
##  Supply chain security: GitHub CLI - checksum validation
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
        package_arch="amd64"
        ;;
    *)
        package_arch="$ARCH"
        ;;
esac

# Download GitHub CLI
gh_cli_url=$(resolve_github_release_asset_url "cli/cli" "contains(\"linux\") and contains(\"${package_arch}\") and endswith(\".deb\")" "latest")
gh_cli_rpm_path=$(download_with_retry "$gh_cli_url")

# Supply chain security - GitHub CLI
hash_url=$(resolve_github_release_asset_url "cli/cli" "endswith(\"checksums.txt\")" "latest")
external_hash=$(get_checksum_from_url "$hash_url" "linux_${package_arch}.rpm" "SHA256")
use_checksum_comparison "$gh_cli_rpm_path" "$external_hash"

# Install GitHub CLI
install_dnfpkgs "$gh_cli_rpm_path"