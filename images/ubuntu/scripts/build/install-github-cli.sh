#!/bin/bash -e
################################################################################
##  File:  install-github-cli.sh
##  Desc:  Install GitHub CLI
##         Must be run as non-root user after homebrew
##  Supply chain security: GitHub CLI - checksum validation
################################################################################
# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

if [[ "$ARCH" == "ppc64le" ]]; then 
    # Placeholder for ppc64le-specific logic
    echo "No actions defined for ppc64le architecture."
elif [[ "$ARCH" == "s390x" ]]; then
    # Placeholder for s390x-specific logic
    echo "No actions defined for s390x architecture."
else
    # Download GitHub CLI
    gh_cli_url=$(resolve_github_release_asset_url "cli/cli" "contains(\"linux\") and contains(\"amd64\") and endswith(\".deb\")" "latest")
    gh_cli_deb_path=$(download_with_retry "$gh_cli_url")

    # Supply chain security - GitHub CLI
    hash_url=$(resolve_github_release_asset_url "cli/cli" "endswith(\"checksums.txt\")" "latest")
    external_hash=$(get_checksum_from_url "$hash_url" "linux_amd64.deb" "SHA256")
    use_checksum_comparison "$gh_cli_deb_path" "$external_hash"

    # Install GitHub CLI
    install_dpkgs "$gh_cli_deb_path"
fi
