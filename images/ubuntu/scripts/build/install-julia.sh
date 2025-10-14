#!/bin/bash -e
################################################################################
##  File:  install-julia.sh
##  Desc:  Install Julia and add to the path
################################################################################

# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

# Set architecture-specific variables using a case statement for clarity
case "$ARCH" in
    "ppc64le")
        triplet="powerpc64le-linux-gnu"
        tar_arch_suffix="linux-ppc64le"
        ;;
    "s390x")
        echo "Julia is not officially available for the s390x architecture."
        exit 0
        ;;
    "x86_64" | *)
        triplet="$ARCH-linux-gnu"
        tar_arch_suffix="linux-$ARCH"
        ;;
esac

# get the latest julia version
json=$(curl -fsSL "https://julialang-s3.julialang.org/bin/versions.json")
julia_version=$(echo "$json" | jq -r --arg triplet "$triplet" '.[].files[] | select(.triplet==$triplet and (.version | contains("-") | not)).version' | sort -V | tail -n1)

# download julia archive
julia_tar_url=$(echo "$json" | jq -r ".[].files[].url | select(endswith(\"julia-${julia_version}-${tar_arch_suffix}.tar.gz\"))")
julia_archive_path=$(download_with_retry "$julia_tar_url")

# extract files and make symlink
julia_installation_path="/usr/local/julia${julia_version}"
mkdir -p "${julia_installation_path}"
tar -C "${julia_installation_path}" -xzf "$julia_archive_path" --strip-components=1
ln -s "${julia_installation_path}/bin/julia" /usr/bin/julia
