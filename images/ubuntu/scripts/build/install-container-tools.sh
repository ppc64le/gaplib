#!/bin/bash -e
################################################################################
##  File:  install-container-tools.sh
##  Desc:  Install container tools: podman, buildah and skopeo onto the image
################################################################################

# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/os.sh
source "$HELPER_SCRIPTS"/install.sh

# Set architecture-specific variables using a case statement for clarity
case "$ARCH" in
    "x86_64")
        package_arch="amd64"
        ;;
    *)
        package_arch="$ARCH"
        ;;
esac

#
# pin podman due to https://github.com/actions/runner-images/issues/7753
#                   https://bugs.launchpad.net/ubuntu/+source/libpod/+bug/2024394
#
if ! is_ubuntu22; then
    install_packages=(podman buildah skopeo)
else
    install_packages=(podman=3.4.4+ds1-1ubuntu1 buildah skopeo)
fi

if is_ubuntu22 && [ "$ARCH" != "ppc64le" ] && [ "$ARCH" != "s390x" ]; then
    # Install containernetworking-plugins for Ubuntu 22
    curl -O http://archive.ubuntu.com/ubuntu/pool/universe/g/golang-github-containernetworking-plugins/containernetworking-plugins_1.1.1+ds1-3build1_"${package_arch}".deb
    dpkg -i containernetworking-plugins_1.1.1+ds1-3build1_"${package_arch}".deb
fi

# Install podman, buildah, skopeo container's tools
update_dpkgs
install_dpkgs "${install_packages[@]}"
mkdir -p /etc/containers
printf "[registries.search]\nregistries = ['docker.io', 'quay.io']\n" | tee /etc/containers/registries.conf

