#!/bin/bash -e
################################################################################
##  File:  configure-apt.sh
##  Desc:  Configure apt, install jq and apt-fast packages.
################################################################################
source $HELPER_SCRIPTS/os.sh
source $HELPER_SCRIPTS/install.sh

# Stop and disable apt-daily upgrade services;
systemctl stop apt-daily.timer >/dev/null
systemctl disable apt-daily.timer >/dev/null
systemctl disable apt-daily.service >/dev/null
systemctl stop apt-daily-upgrade.timer >/dev/null
systemctl disable apt-daily-upgrade.timer >/dev/null
systemctl disable apt-daily-upgrade.service >/dev/null

# Enable retry logic for apt up to 10 times
echo "APT::Acquire::Retries \"10\";" > /etc/apt/apt.conf.d/80-retries

# Configure apt to always assume Y
echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# APT understands a field called Phased-Update-Percentage which can be used to control the rollout of a new version. It is an integer between 0 and 100.
# In case you have multiple systems that you want to receive the same set of updates, 
# you can set APT::Machine-ID to a UUID such that they all phase the same, 
# or set APT::Get::Never-Include-Phased-Updates or APT::Get::Always-Include-Phased-Updates to true such that APT will never/always consider phased updates.
# apt-cache policy pkgname
echo 'APT::Get::Always-Include-Phased-Updates "true";' > /etc/apt/apt.conf.d/99-phased-updates

# Fix bad proxy and http headers settings
cat <<EOF >> /etc/apt/apt.conf.d/99bad_proxy
Acquire::http::Pipeline-Depth 0;
Acquire::http::No-Cache true;
Acquire::BrokenProxy    true;
EOF

# Uninstall unattended-upgrades
apt-get -qq purge unattended-upgrades >/dev/null |& tee -a /tmp/install.errors

echo 'APT sources'
if ! is_ubuntu24; then
    cat /etc/apt/sources.list
else
    cat /etc/apt/sources.list.d/ubuntu.sources
fi

update_dpkgs
# Install jq
install_dpkgs jq

if ! is_ubuntu24; then
    # Install apt-fast using quick-install.sh
    # https://github.com/ilikenwf/apt-fast
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"
fi
