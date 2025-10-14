#!/bin/bash -e
################################################################################
##  File:  install-miniconda.sh
##  Desc:  Install miniconda
################################################################################

# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/etc-environment.sh

# Install Miniconda
curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-"${ARCH}".sh -o miniconda.sh \
    && chmod +x miniconda.sh \
    && ./miniconda.sh -b -p /usr/share/miniconda \
    && rm miniconda.sh

CONDA=/usr/share/miniconda
set_etc_environment_variable "CONDA" "${CONDA}"

ln -s $CONDA/bin/conda /usr/bin/conda