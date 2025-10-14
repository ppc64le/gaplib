#!/bin/bash
set -e  # Exit on any error

# Default environment variable values
ARCH=${ARCH:-$(uname -m)}
IMAGE_OS=$1
IMAGE_VERSION=$2
# shellcheck disable=SC2034
WORKER_TYPE=${3:-""} # Default to "" if WORKER_TYPE is not set
# shellcheck disable=SC2034
WORKER_CPU=${4:-""} # Default to "" if WORKER_CPU is not set
# shellcheck disable=SC2034
SETUP=${5:-"minimal"} # Default to "minimal" if SETUP is not set

# shellcheck disable=SC2034
# shellcheck disable=SC2001
toolset_file_name="toolset-$(echo "$2" | sed 's/\.//g').json"
image_folder="/var/tmp/imagegeneration-${IMAGE_OS}-${IMAGE_VERSION}"
helper_script_folder="${image_folder}/helpers"
installer_script_folder="${image_folder}/installers"
imagedata_file="${image_folder}/imagedata.json"

# shellcheck disable=SC2034
HELPER_SCRIPTS="${helper_script_folder}"
# shellcheck disable=SC2034
IMAGE_FOLDER="${image_folder}"
# shellcheck disable=SC2034
IMAGEDATA_FILE="${imagedata_file}"
# shellcheck disable=SC2034
DEBIAN_FRONTEND="noninteractive"
# shellcheck disable=SC2034
INSTALLER_SCRIPT_FOLDER="${installer_script_folder}"
# shellcheck disable=SC2034
DOCKERHUB_PULL_IMAGES="NO"
PATCH_FILE="${PATCH_FILE:-runner-sdk8-${ARCH}.patch}"