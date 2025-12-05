#!/bin/bash
set -e  # Exit on any error
set -o pipefail  # Fail if any command in a pipeline fails

CURRENT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "${CURRENT_DIR}"/setup_vars.sh
# shellcheck disable=SC1091
source "${CURRENT_DIR}"/run_script.sh
# Configure limits
run_script "${INSTALLER_SCRIPT_FOLDER}/configure-limits.sh" 

# Configure image data
run_script "${INSTALLER_SCRIPT_FOLDER}/configure-image-data.sh" "IMAGE_VERSION" "IMAGEDATA_FILE"

# Configure environment
run_script "${INSTALLER_SCRIPT_FOLDER}/configure-environment.sh" "IMAGE_OS" "IMAGE_VERSION" "HELPER_SCRIPTS"

if [[ "$IMAGE_OS" == *"ubuntu"* ]]; then
    # Add apt wrapper to implement retries
    run_script "${INSTALLER_SCRIPT_FOLDER}/configure-apt-mock.sh"
    echo "Setting user ubuntu with sudo privileges"

    # Install Configure apt
    run_script "${INSTALLER_SCRIPT_FOLDER}/configure-apt.sh" "DEBIAN_FRONTEND" "HELPER_SCRIPTS"

    run_script "${INSTALLER_SCRIPT_FOLDER}/install-apt-vital.sh" "DEBIAN_FRONTEND" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH"

    run_script "${INSTALLER_SCRIPT_FOLDER}/install-apt-common.sh" "DEBIAN_FRONTEND" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH"

    run_script "${INSTALLER_SCRIPT_FOLDER}/configure-dpkg.sh" "DEBIAN_FRONTEND" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH"
elif [[ "$IMAGE_OS" == *"centos"* ]]; then
    # Add apt wrapper to implement retries
    run_script "${INSTALLER_SCRIPT_FOLDER}/configure-yum-mock.sh"
    echo "Setting user ubuntu with sudo privileges"

    # Install Configure apt
    run_script "${INSTALLER_SCRIPT_FOLDER}/configure-dnf.sh" "DEBIAN_FRONTEND" "HELPER_SCRIPTS"

    run_script "${INSTALLER_SCRIPT_FOLDER}/install-dnf-vital.sh" "DEBIAN_FRONTEND" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH"

    run_script "${INSTALLER_SCRIPT_FOLDER}/install-dnf-common.sh" "DEBIAN_FRONTEND" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH"

    run_script "${INSTALLER_SCRIPT_FOLDER}/configure-dnfpkg.sh" "DEBIAN_FRONTEND" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH" 

fi

# Initialize an empty array for script files
SCRIPT_FILES=()

# Define scripts for each setup type
if [ "$SETUP" == "minimal" ]; then
    # List of scripts to be executed for a minimal setup
    SCRIPT_FILES=(
        "install-actions-cache.sh"
        "install-dotnetcore-sdk.sh"
        "install-runner-package.sh"
        "install-git.sh"
        "install-git-lfs.sh"
        "install-github-cli.sh"
        "install-python.sh"
        "install-zstd.sh"
    )
elif [ "$SETUP" == "complete" ]; then
    echo "Starting complete setup for $IMAGE_VERSION"
    if [[ "$IMAGE_VERSION" == "24.04" ]]; then
        # List of scripts to be executed
        SCRIPT_FILES=(
            "install-actions-cache.sh"
            "install-dotnetcore-sdk.sh"
            "install-runner-package.sh"
            "install-azcopy.sh"
            "install-azure-cli.sh"
            "install-azure-devops-cli.sh"
            "install-bicep.sh"
            "install-apache.sh"
            "install-aws-tools.sh"
            "install-clang.sh"
            "install-swift.sh"
            "install-cmake.sh"
            "install-codeql-bundle.sh"
            "install-container-tools.sh"
            "install-microsoft-edge.sh"
            "install-gcc-compilers.sh"
            "install-firefox.sh"
            "install-gfortran.sh"
            "install-git.sh"
            "install-git-lfs.sh"
            "install-github-cli.sh"
            "install-google-chrome.sh"
            "install-google-cloud-cli.sh"
            "install-haskell.sh"
            "install-java-tools.sh"
            "install-kubernetes-tools.sh"
            "install-miniconda.sh"
            "install-kotlin.sh"
            "install-mysql.sh"
            "install-nginx.sh"
            "install-nvm.sh"
            "install-nodejs.sh"
            "install-bazel.sh"
            "install-php.sh"
            "install-postgresql.sh"
            "install-pulumi.sh"
            "install-ruby.sh"
            "install-rust.sh"
            "install-julia.sh"
            "install-selenium.sh"
            "install-packer.sh"
            "install-vcpkg.sh"
            "install-yq.sh"
            "install-android-sdk.sh"
            "install-pypy.sh"
            "install-python.sh"
            "install-zstd.sh"
            "install-ninja.sh"
        )
    elif [[ "$IMAGE_VERSION" == "22.04" ]]; then
        # List of scripts to be executed
        SCRIPT_FILES=(
            "install-actions-cache.sh"
            "install-dotnetcore-sdk.sh"
            "install-runner-package.sh"
            "install-azcopy.sh"
            "install-azure-cli.sh"
            "install-azure-devops-cli.sh"
            "install-bicep.sh"
            "install-aliyun-cli.sh"
            "install-apache.sh"
            "install-aws-tools.sh"
            "install-clang.sh"
            "install-swift.sh"
            "install-cmake.sh"
            "install-codeql-bundle.sh"
            "install-container-tools.sh"
            "install-firefox.sh"
            "install-microsoft-edge.sh"
            "install-gcc-compilers.sh"
            "install-gfortran.sh"
            "install-git.sh"
            "install-git-lfs.sh"
            "install-github-cli.sh"
            "install-google-chrome.sh"
            "install-google-cloud-cli.sh"
            "install-haskell.sh"
            "install-heroku.sh"
            "install-java-tools.sh"
            "install-kubernetes-tools.sh"
            "install-oc-cli.sh"
            "install-leiningen.sh"
            "install-miniconda.sh"
            "install-mono.sh"
            "install-kotlin.sh"
            "install-mysql.sh"
            "install-mssql-tools.sh"
            "install-sqlpackage.sh"
            "install-nginx.sh"
            "install-nvm.sh"
            "install-nodejs.sh"
            "install-bazel.sh"
            "install-oras-cli.sh"
            "install-php.sh"
            "install-postgresql.sh"
            "install-pulumi.sh"
            "install-ruby.sh"
            "install-rlang.sh"
            "install-rust.sh"
            "install-julia.sh"
            "install-sbt.sh"
            "install-selenium.sh"
            "install-terraform.sh"
            "install-packer.sh"
            "install-vcpkg.sh"
            "install-yq.sh"
            "install-android-sdk.sh"
            "install-pypy.sh"
            "install-python.sh"
            "install-zstd.sh"
            "install-ninja.sh"
        )
    else
        echo "Invalid IMAGE_VERSION value for complete setup. Please set IMAGE_VERSION to contain '22.04' or '24.04'."
        exit 1
    fi
else
    echo "Invalid SETUP value. Please set SETUP to 'minimal' or 'complete'."
    exit 1
fi

# Loop through all scripts and execute them
for SCRIPT_FILE in "${SCRIPT_FILES[@]}"; do
    SCRIPT_PATH="${INSTALLER_SCRIPT_FOLDER}/${SCRIPT_FILE}"
    run_script "$SCRIPT_PATH" "DEBIAN_FRONTEND" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH" "IMAGE_FOLDER"
done

# Install and configure snap and lxd unless skipped
if [ "${SKIP_SNAP_LXD:-false}" != "true" ]; then
    run_script "${INSTALLER_SCRIPT_FOLDER}/install-snap.sh" "DEBIAN_FRONTEND" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH" "IMAGE_FOLDER"
    run_script "${INSTALLER_SCRIPT_FOLDER}/install-lxd.sh" "DEBIAN_FRONTEND" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH" "IMAGE_FOLDER"
    run_script "${INSTALLER_SCRIPT_FOLDER}/configure-snap.sh" "HELPER_SCRIPTS" "ARCH"
fi

run_script "${INSTALLER_SCRIPT_FOLDER}/install-docker.sh" "DOCKERHUB_PULL_IMAGES" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH"
    
run_script "${INSTALLER_SCRIPT_FOLDER}/install-pipx-packages.sh" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH"

run_script "${INSTALLER_SCRIPT_FOLDER}/install-homebrew.sh" "DEBIAN_FRONTEND" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH"

# echo 'Rebooting VM...'
# sudo reboot

# The cleanup script is executed after the reboot.
"${INSTALLER_SCRIPT_FOLDER}/cleanup.sh"

# Configure system settings
run_script "${INSTALLER_SCRIPT_FOLDER}/configure-system.sh" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH" "IMAGE_FOLDER"
