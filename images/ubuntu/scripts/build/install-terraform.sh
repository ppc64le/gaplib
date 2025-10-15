#!/bin/bash -e
################################################################################
##  File:  install-terraform.sh
##  Desc:  Install terraform
################################################################################

# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

# Set architecture-specific variables using a case statement for clarity
case "$ARCH" in
    "ppc64le")
        wget -O /usr/local/bin/terraform https://ftp2.osuosl.org/pub/ppc64el/terraform/terraform-1.4.6
        chmod +x /usr/local/bin/terraform
        exit 0
        ;;
    "s390x")
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

# Install Terraform
download_url=$(curl -fsSL https://api.releases.hashicorp.com/v1/releases/terraform/latest | jq -r --arg arch "$package_arch" '.builds[] | select((.arch==$arch) and (.os=="linux")).url')
archive_path=$(download_with_retry "${download_url}")
unzip -qq "$archive_path" -d /usr/local/bin


