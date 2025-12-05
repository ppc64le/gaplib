#!/bin/bash
set -e  # Exit on any error

# Define Help/Usage Function ---
usage() {
    echo "Usage: $(basename "$0") [OS] [VERSION] [WORKER_TYPE] [WORKER_CPU] [SETUP_TYPE] [FLAGS]"
    echo ""
    echo "Positional Arguments:"
    echo "  1. OS            (e.g., ubuntu)"
    echo "  2. VERSION       (e.g., 22.04)"
    echo "  3. WORKER_TYPE   (Optional, default: empty)"
    echo "  4. WORKER_CPU    (Optional, default: empty)"
    echo "  5. SETUP_TYPE    (Optional, default: minimal)"
    echo ""
    echo "Flags:"
    echo "  --lxd-debug             Enable LXD debug mode (non-ephemeral containers)"
    echo "  --skip-snap-lxd         Skip snap and lxd installation and configuration"
    echo "  --skip-lxd-img-export   Skip LXD image export"
    echo "  --skip-lxd-img-primer   Skip LXD image primer"
    echo "  --skip-lxd-publish      Skip LXD publish"
    echo "  --skip-lxd-snapshot     Skip LXD snapshot"
    echo "  -h, --help              Show this help"
    echo ""
    # Use return 1 instead of exit 1 because this script is sourced
    return 1
}

# Initialize Defaults ---
LXD_DEBUG=false
SKIP_SNAP_LXD=false
SKIP_LXD_IMG_EXPORT=false
SKIP_LXD_IMG_PRIMER=false
SKIP_LXD_PUBLISH=false
SKIP_LXD_SNAPSHOT=false
ARCH=${ARCH:-$(uname -m)}
PATCH_FILE="${PATCH_FILE:-runner-sdk8-${ARCH}.patch}"

# Parse Arguments ---
# We use a temporary array to store non-flag arguments to avoid clobbering 
# the parent shell's positional parameters with 'set --'.
clean_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --lxd-debug)
            # shellcheck disable=SC2034
            LXD_DEBUG=true
            ;;
        --skip-snap-lxd)
            # shellcheck disable=SC2034
            SKIP_SNAP_LXD=true
            ;;
        --skip-lxd-img-export)
            # shellcheck disable=SC2034
            SKIP_LXD_IMG_EXPORT=true
            ;;
        --skip-lxd-img-primer)
            # shellcheck disable=SC2034
            SKIP_LXD_IMG_PRIMER=true
            ;;
        --skip-lxd-publish)
            # shellcheck disable=SC2034
            SKIP_LXD_PUBLISH=true
            ;;
        --skip-lxd-snapshot)
            # shellcheck disable=SC2034
            SKIP_LXD_SNAPSHOT=true
            ;;
        -h|--help)
            usage
            # We return out of the script entirely if help is asked
            # shellcheck disable=SC2317
            return 0 2>/dev/null || exit 0
            ;;
        --*)
            echo "Unknown option: $1" >&2
            usage
            # shellcheck disable=SC2317
            return 1 2>/dev/null || exit 1
            ;;
        *)
            clean_args+=("$1")
            ;;
    esac
    shift
done

# Assign Variables from Cleaned Arguments ---
# We map the array indices to the specific variables.
# This handles cases where flags were passed before, between, or after arguments.

IMAGE_OS="${clean_args[0]}"
IMAGE_VERSION="${clean_args[1]}"
# shellcheck disable=SC2034
WORKER_TYPE="${clean_args[2]:-}"       # Default to empty if not provided
# shellcheck disable=SC2034
WORKER_CPU="${clean_args[3]:-}"        # Default to empty if not provided
# shellcheck disable=SC2034
SETUP="${clean_args[4]:-minimal}"      # Default to "minimal" if not provided

# Validate required arguments
if [[ -z "$IMAGE_OS" ]] || [[ -z "$IMAGE_VERSION" ]]; then
    echo "Error: IMAGE_OS and IMAGE_VERSION are required."
    usage
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

# Define Dependent Variables ---
# shellcheck disable=SC2001
# shellcheck disable=SC2034
toolset_file_name="toolset-$(echo "$IMAGE_VERSION" | sed 's/\.//g').json"
image_folder="/var/tmp/imagegeneration-${IMAGE_OS}-${IMAGE_VERSION}"
helper_script_folder="${image_folder}/helpers"
installer_script_folder="${image_folder}/installers"
imagedata_file="${image_folder}/imagedata.json"

# Export variables for use in other scripts
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
