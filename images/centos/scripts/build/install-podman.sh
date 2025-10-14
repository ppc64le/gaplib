#!/bin/bash -e
################################################################################
##  File:  install-snap.sh
##  Desc:  Install snapd
################################################################################
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

dnf -y install podman