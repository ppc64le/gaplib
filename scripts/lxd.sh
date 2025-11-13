#!/bin/bash

HELPERS_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/helpers"

usage() {
    echo "lxd.sh [flags]"
    echo ""
    echo "Where flags:"
    echo "--export-image               Publish and Export the built image on completion of build"
    echo "                             defaults to false"
    echo "-h, --help                   Display this usage information"
    exit 1
}

parse_args() {
    EXPORT_IMAGE=false
    POSITIONAL_ARGS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --export-image)
                EXPORT_IMAGE=true
                ;;
            -h|--help)
                usage
                ;;
            --*)
                echo "Unknown option: $1" >&2
                usage
                ;;
            *)
                POSITIONAL_ARGS+=("$1")  # anything not starting with -- is positional
                ;;
        esac
        shift
    done

    # Rebuild positional arguments
    set -- "${POSITIONAL_ARGS[@]}"

    # Export flags for rest of the script
    export EXPORT_IMAGE
}

# Parse optional arguments before passing positional args over
parse_args "$@"
set -- "${POSITIONAL_ARGS[@]}"

# shellcheck disable=SC1091
source "${HELPERS_DIR}"/setup_vars.sh
# shellcheck disable=SC1091
source "${HELPERS_DIR}"/setup_img.sh
# shellcheck disable=SC1091
source "${HELPERS_DIR}"/run_script.sh

msg() {
    # shellcheck disable=SC2046
    echo $(date +"%Y-%m-%dT%H:%M:%S%:z") "$*"
}

ensure_lxd() {
    if ! command -v lxd &> /dev/null; then
        echo "LXD is not installed."
        if ! command -v snap &> /dev/null; then
            echo "Snap is not installed. Installing Snap..."
            run_script "${HOST_INSTALLER_SCRIPT_FOLDER}/install-snap.sh" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH"
            echo "Snap installed successfully."
        fi
        echo "Installing LXD using Snap..."
        run_script "${HOST_INSTALLER_SCRIPT_FOLDER}/install-lxd.sh" "HELPER_SCRIPTS" "INSTALLER_SCRIPT_FOLDER" "ARCH"
        if command -v lxd &> /dev/null; then
            echo "LXD installed successfully."
        else
            echo "Failed to install LXD. Please check your system configuration."
            exit 1
        fi
    else
        echo "LXD is already installed. Checking its version..."

        LATEST_LTS_CHANNEL=$(snap info lxd | grep -E '(^\s*[0-9]+\.0/stable)' | awk '{print $1}' | sed 's|/stable:||' | sort -rV | head -n 1)

        # Get the currently tracked channel from the snap list output.
        CURRENT_LTS_CHANNEL=$(snap list lxd | awk 'NR==2 {print $4}' | sed 's|/stable.*||')

        echo "Currently installed channel: ${CURRENT_LTS_CHANNEL}"
        echo "Latest available LTS channel: ${LATEST_LTS_CHANNEL}"

        # Compare the current channel with the latest available LTS channel.
        if [ "$CURRENT_LTS_CHANNEL" != "$LATEST_LTS_CHANNEL" ]; then
            echo
            echo "An upgrade is recommended."
            echo "To prevent disruption to your existing setup, please upgrade manually."
            echo "Run the following command to switch to the latest LTS channel:"
            echo
            echo "  sudo snap refresh lxd --channel=${LATEST_LTS_CHANNEL}/stable"
            echo
            echo "Note: Always back up your data before performing a channel switch."
        else
            echo "You are already on the latest available LXD LTS channel. No action needed."
        fi
        echo "Checking list of refreshable snaps..."
        sudo snap refresh --list
  
        # Hold the autorefresh for LXD
        sudo snap refresh --hold lxd
    fi
}

build_image() {
  set -e

  local IMAGE_ALIAS="${IMAGE_ALIAS:-${IMAGE_OS}-${IMAGE_VERSION}-${ARCH}${WORKER_TYPE}${WORKER_CPU}}"
  local BUILD_PREREQS_PATH
  BUILD_PREREQS_PATH="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

  if [ ! -d "${BUILD_PREREQS_PATH}" ]; then
    msg "Check the BUILD_PREREQS_PATH specification" >&2
    return 3
  fi

  local BUILD_CONTAINER
  BUILD_CONTAINER="gha-builder-$(date +%s)"

  # Trap INT (Ctrl+C), TERM (kill), and EXIT signals to guarantee cleanup.
  # shellcheck disable=SC2064
  trap "{
    msg \"Signal caught! Executing cleanup for container ${BUILD_CONTAINER}...\"
    if lxc info \"${BUILD_CONTAINER}\" &>/dev/null; then
      msg \"Stopping container ${BUILD_CONTAINER} to trigger deletion...\"
      # Container is ephemeral, so stopping it will also delete it.
      lxc stop -f \"${BUILD_CONTAINER}\"
    else
      msg \"Container ${BUILD_CONTAINER} already gone.\"
    fi
  }" INT TERM EXIT

  msg "Launching ephemeral build container ${BUILD_CONTAINER} from image ${LXD_CONTAINER}"
  lxc launch "${LXD_CONTAINER}" "${BUILD_CONTAINER}" --ephemeral
  lxc ls

  # Give container some time to wake up and remap the filesystem
  for ((i = 0; i < 90; i++)); do
    local CHECK
    CHECK=$(lxc exec "${BUILD_CONTAINER}" -- stat "${BUILD_HOME}" 2>/dev/null || true)
    if [ -n "${CHECK}" ]; then
      break
    fi
    sleep 2s
  done

  if [ -z "${CHECK}" ]; then
    msg "Unable to start the build container" >&2
    return 2
  fi

  # shellcheck disable=SC2154
  msg "Copy the ${image_folder} contents into the gha-builder"
  lxc file push "${image_folder}" "${BUILD_CONTAINER}/var/tmp/" --recursive
  lxc exec "${BUILD_CONTAINER}" ls "${image_folder}"

  msg "Copy the register-runner.sh script into gha-builder"
  lxc file push --mode 0755 "${BUILD_PREREQS_PATH}/helpers/register-runner.sh" "${BUILD_CONTAINER}/opt/register-runner.sh"

  msg "Copy the /etc/rc.local - required in case podman is used"
  lxc file push --mode 0755 "${BUILD_PREREQS_PATH}/assets/rc.local" "${BUILD_CONTAINER}/etc/rc.local"

  msg "Copy the gha-service unit file into gha-builder"
  lxc file push "${BUILD_PREREQS_PATH}/assets/gha-runner.service" "${BUILD_CONTAINER}/etc/systemd/system/gha-runner.service"

  msg "Copy the apt and dpkg overrides into gha-builder - these prevent doc files from being installed"
  lxc file push --mode 0644 "${BUILD_PREREQS_PATH}/assets/99synaptics" "${BUILD_CONTAINER}/etc/apt/apt.conf.d/99synaptics"
  lxc file push --mode 0644 "${BUILD_PREREQS_PATH}/assets/01-nodoc" "${BUILD_CONTAINER}/etc/dpkg/dpkg.cfg.d/01-nodoc"

  msg "Running setup_install.sh (as root)"
  # shellcheck disable=SC1073
  # shellcheck disable=SC2154
  if ! lxc exec "${BUILD_CONTAINER}" --user 0 --group 0 -- \
    bash -c 'exec "$@"' _ "${helper_script_folder}/setup_install.sh" "${IMAGE_OS}" "${IMAGE_VERSION}" "${WORKER_TYPE}" "${WORKER_CPU}" "${SETUP}"; then

    msg "!!! The installation script inside the container failed. Triggering cleanup. !!!" >&2
    return 1 # Exit with an error code to trigger the trap and signal failure
  fi

  msg "Setting user runner with sudo privileges"
  lxc exec "${BUILD_CONTAINER}" --user 0 --group 0 -- bash -c "useradd -c 'Action Runner' -m -s /bin/bash runner && usermod -L runner && echo 'runner ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/runner && chmod 440 /etc/sudoers.d/runner"

  msg "Adding runner user to required groups"
  lxc exec "${BUILD_CONTAINER}" --user 0 --group 0 -- bash -c "usermod -aG adm,users,systemd-journal,docker,lxd runner"
  
  msg "Running post-generation scripts (as root)"
  lxc exec "${BUILD_CONTAINER}" --user 0 --group 0 -- bash -c "find /opt/post-generation -mindepth 1 -maxdepth 1 -type f -name '*.sh' -exec bash {} \;"

  # --------------------- CRITICAL SECTION START ---------------------
  # The following operations (delete, snapshot, publish) are not safe to run in parallel.
  # We use `flock` to create a lock file. Only one script instance can hold the lock
  # at a time, forcing other instances to wait here. This prevents race conditions
  
  local LXD_PUBLISH_LOCK="/var/lock/lxd-publish.lock"
  exec 200>"${LXD_PUBLISH_LOCK}" # Open a file descriptor for the lock file
  msg "Attempting to acquire lock for image publication... (${LXD_PUBLISH_LOCK})"
  flock 200 # This command will wait until it can acquire an exclusive lock on FD 200

  msg "Lock acquired. Proceeding with atomic image publication."

  msg "Deleting old image (by fingerprint from alias ${IMAGE_ALIAS})"
  if lxc image info "${IMAGE_ALIAS}" >/dev/null 2>&1; then
    FINGERPRINT=$(lxc image info "${IMAGE_ALIAS}" | awk '/^Fingerprint:/ {print $2; exit}')
    if [ -n "${FINGERPRINT}" ]; then
        msg "Found fingerprint ${FINGERPRINT} for alias ${IMAGE_ALIAS}. Deleting image ${FINGERPRINT}..."
        lxc image delete "${FINGERPRINT}"
        msg "Image (fingerprint ${FINGERPRINT}) deleted successfully."
    else
        msg "Could not determine fingerprint for alias ${IMAGE_ALIAS}." >&2
        exit 1
    fi
  else
    msg "No existing image/alias named ${IMAGE_ALIAS} found."
  fi

  msg "Runner build complete."

  if [[ "${EXPORT_IMAGE}" == true ]]; then
    lxc snapshot "${BUILD_CONTAINER}" "build-snapshot"

    msg "Publishing snapshot as new image: ${IMAGE_ALIAS}"
    lxc publish "${BUILD_CONTAINER}/build-snapshot" -f --alias "${IMAGE_ALIAS}" \
      --compression none \
      description="GitHub Actions ${IMAGE_OS} ${IMAGE_VERSION} Runner for ${ARCH}" \
      properties.build.commit="${BUILD_SHA}" \
      properties.build.date="${BUILD_DATE}"

    msg "Image publication complete. Releasing lock."
    # The lock on FD 200 is automatically released when the script or function exits.
    # ---------------------- CRITICAL SECTION END ----------------------

    msg "Export the image to ${EXPORT} for use elsewhere"
    lxc image export "${IMAGE_ALIAS}" "${EXPORT}/${IMAGE_OS}-${IMAGE_VERSION}-${ARCH}${WORKER_TYPE}${WORKER_CPU}"

    local PRIMER_CONTAINER
    PRIMER_CONTAINER="primer-$(date +%s)"
    msg "Priming the filesystem by launching the newly built container"
    lxc launch "${IMAGE_ALIAS}" "${PRIMER_CONTAINER}"
    lxc rm -f "${PRIMER_CONTAINER}"
  else
    msg "Export flag not set. Skipping publish and export"
  fi 

  # Before exiting successfully, clear the trap so it doesn't run again on the main script's exit.
  trap - INT TERM EXIT
  lxc delete -f "${BUILD_CONTAINER}"
  return 0
}

run() {
  ensure_lxd "$@"
  build_image "$@"
  return $?
}

prolog() {
  PATH=/snap/bin:${PATH}
  ACTION_RUNNER="https://github.com/actions/runner"
  EXPORT="/opt/distro"
  HOST_OS_NAME=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"' | tr '[:upper:]' '[:lower:]' | awk '{print $1}')
  # shellcheck disable=SC2034
  # shellcheck disable=SC2002
  HOST_OS_VERSION=$(cat /etc/os-release | grep -E 'VERSION_ID' | cut -d'=' -f2 | tr -d '"')
  HOST_INSTALLER_SCRIPT_FOLDER="${HELPERS_DIR}/../../images/${HOST_OS_NAME}/scripts/build"
  BUILD_HOME="/home"
  BUILD_SHA=$(git rev-parse HEAD)
  BUILD_DATE=$(date -u)
  LXD_CONTAINER="${IMAGE_OS}:${IMAGE_VERSION}"

  mkdir -p ${EXPORT}
}

prolog
run "$@"
RC=$?
exit ${RC}