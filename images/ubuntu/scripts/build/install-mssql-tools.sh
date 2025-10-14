#!/bin/bash -e
################################################################################
##  File:  install-mssql-tools.sh
##  Desc:  Install MS SQL Server client tools (https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-2017)
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

export ACCEPT_EULA=Y

update_dpkgs
install_dpkgs mssql-tools unixodbc-dev
apt-get -f install
ln -s /opt/mssql-tools/bin/* /usr/local/bin/



