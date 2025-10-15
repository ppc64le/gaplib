#!/bin/bash -e
################################################################################
##  File:  install-lxd.sh
##  Desc:  Install lxd
################################################################################
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

LATEST_LTS_CHANNEL=$(snap info lxd | grep -E '(^\s*[0-9]+\.0/stable)' | awk '{print $1}' | sed 's|/stable:||' | sort -rV | head -n 1)

if [ -n "$LATEST_LTS_CHANNEL" ]; then
    echo "The latest LTS channel is: ${LATEST_LTS_CHANNEL}/stable"
else
    echo "Could not determine the latest LTS channel."
fi

# Install 5.21 LTS LXD version using snap
echo "Installing LXD version ${LATEST_LTS_CHANNEL} using snap..."
sudo snap install lxd --channel="${LATEST_LTS_CHANNEL}/stable"

echo "Printing LXD info..."
lxc info

echo "Checking list of refreshable snaps..."
sudo snap refresh --list

echo "Checking the status of snap.lxd.daemon..."
ensure_service_is_active snap.lxd.daemon

# Hold the autorefresh for LXD as it can cause unwanted service-disruptions 
sudo snap refresh --hold lxd

# Initialize LXD using the preseed configuration file for automated setup.
echo "Initializing LXD with preseed configuration..."
if [[ -f "$INSTALLER_SCRIPT_FOLDER/lxd-preseed.yaml" ]]; then
    cat "$INSTALLER_SCRIPT_FOLDER/lxd-preseed.yaml" | sudo lxd init --preseed
else
    echo "Warning: lxd-preseed.yaml not found. Initializing with defaults."
    sudo lxd init --auto
fi

echo "LXD installation and initialization are complete!"