#!/bin/bash -e
################################################################################
##  File:  install-lxd.sh
##  Desc:  Install lxd
################################################################################
source $HELPER_SCRIPTS/install.sh

# Install 5.21 LTS LXD version using snap
echo "Installing LXD version 5.21 using snap..."
sudo snap install lxd --channel="5.21/stable"

echo "Printing LXD info..."
lxc info

echo "Checking list of refreshable snaps..."
sudo snap refresh --list

echo "Checking the status of snap.lxd.daemon..."
ensure_service_is_active snap.lxd.daemon

# Hold the autorefresh for LXD as it can cause unwanted service-disruptions 
sudo snap refresh --hold lxd

# Initialize LXD
echo "Initializing LXD..."
cat $INSTALLER_SCRIPT_FOLDER/lxd-preseed.yaml | sudo -i lxd init --preseed
echo "LXD is ready to use!"
