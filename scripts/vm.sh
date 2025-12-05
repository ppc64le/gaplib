#!/bin/bash
set -e  # Exit on any error

HELPERS_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/helpers"

# shellcheck disable=SC1091
source "${HELPERS_DIR}"/setup_vars.sh
# shellcheck disable=SC1091
source "${HELPERS_DIR}"/setup_img.sh
# shellcheck disable=SC1091
source "${HELPERS_DIR}"/run_script.sh

BUILD_PREREQS_PATH="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

msg() {
    # shellcheck disable=SC2046
    echo $(date +"%Y-%m-%dT%H:%M:%S%:z") "$*"
}

if [ ! -d "${BUILD_PREREQS_PATH}" ]; then
  msg "Check the BUILD_PREREQS_PATH specification" >&2
  return 3
fi

if [[ "$IMAGE_OS" == *"ubuntu"* ]]; then
  msg "Copy the apt and dpkg overrides into gha-builder - these prevent doc files from being installed"
  cp -r "${BUILD_PREREQS_PATH}/assets/99synaptics" "/etc/apt/apt.conf.d/99synaptics"
  chmod -R 0644 /etc/apt/apt.conf.d/99synaptics
  cp -r "${BUILD_PREREQS_PATH}/assets/01-nodoc" "/etc/dpkg/dpkg.cfg.d/01-nodoc"
  chmod -R 0644 /etc/dpkg/dpkg.cfg.d/01-nodoc
fi

msg "Copy the register-runner.sh script into gha-builder"
cp -r "${BUILD_PREREQS_PATH}"/helpers/register-runner.sh "/opt/register-runner.sh"
chmod -R 0755 /opt/register-runner.sh

msg "Copy the /etc/rc.local - required in case podman is used"
cp -r "${BUILD_PREREQS_PATH}"/assets/rc.local "/etc/rc.local"
chmod -R 0755 /etc/rc.local

msg "Copy the gha-service unit file into gha-builder"
cp -r "${BUILD_PREREQS_PATH}"/assets/gha-runner.service "/etc/systemd/system/gha-runner.service"
chmod -R 0755 /etc/systemd/system/gha-runner.service

# shellcheck disable=SC2154
sudo bash -c 'exec "$@"' _ "${HELPER_SCRIPTS}/setup_install.sh" "${clean_args[@]}" "${forward_args[@]}"

sudo bash -c 'id -u runner >/dev/null 2>&1 || (useradd -c "Action Runner" -m -s /bin/bash runner && usermod -L runner && echo "runner ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/runner && chmod 440 /etc/sudoers.d/runner)'

sudo bash -c "usermod -aG adm,users,systemd-journal,docker,lxd runner"

sudo su -c "find /opt/post-generation -mindepth 1 -maxdepth 1 -type f -name '*.sh' -exec bash {} \;"