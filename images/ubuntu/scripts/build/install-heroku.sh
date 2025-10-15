#!/bin/bash -e
################################################################################
##  File:  install-heroku.sh
##  Desc:  Install Heroku CLI. Based on instructions found here: https://devcenter.heroku.com/articles/heroku-cli
################################################################################
# Source the helpers for use with the script
# shellcheck disable=SC1091
source "$HELPER_SCRIPTS"/install.sh

# Set architecture-specific variables using a case statement for clarity
case "$ARCH" in
    "ppc64le" | "s390x")
        echo "No actions defined for $ARCH architecture."
        exit 0
        ;;
    *)
        ;;
esac

REPO_URL="https://cli-assets.heroku.com/channels/stable/apt"
GPG_KEY="/usr/share/keyrings/heroku.gpg"
REPO_PATH="/etc/apt/sources.list.d/heroku.list"

# add heroku repository to apt
curl -fsSL "${REPO_URL}/release.key" | gpg --dearmor -o $GPG_KEY
echo "deb [trusted=yes] $REPO_URL ./" > $REPO_PATH

# install heroku
update_dpkgs
install_dpkgs heroku

# remove heroku's apt repository
rm $REPO_PATH
rm $GPG_KEY

