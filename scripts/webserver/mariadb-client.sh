#!/bin/bash

# Check for USERNAME and set it if not found
[[ -z "$USERNAME" ]] && USERNAME=${SUDO_USER:-$USER}

# Check for HOME_DIRECTORY and set it if not found
[[ -z "$HOME_DIRECTORY" ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
[[ -z "$DOTBASE" ]] && DOTBASE=$HOME_DIRECTORY/.dotfiles

#############
# Functions #
#############

# Source function utils
. $DOTBASE/functions/utils.sh

apt_quiet install wget software-properties-common -y
if ! cmd_exists mysql; then
    wget -q https://downloads.mariadb.com/MariaDB/mariadb_repo_setup

    if [ -f mariadb_repo_setup ]; then
        chmod +x mariadb_repo_setup
        ./mariadb_repo_setup --mariadb-server-version="mariadb-10.6" >/dev/null 2>&1
        apt_quiet update && apt_quiet install mariadb-client -y
        rm mariadb_repo_setup
    else
        echo "Error downloading MariaDB repo setup file. Please run mariadb-setup again."
    fi

fi

# Seed client config file for SSL
SSL_CONF_FILE="$DOTBASE/scripts/webserver/mariadb-client.cnf"
SSL_CONF_DESTINATION="/etc/mysql/mariadb.conf.d/99-client-ssl.cnf"

if [ -f $SSL_CONF_FILE ]; then
    cp $SSL_CONF_FILE $SSL_CONF_DESTINATION
fi

# Check that file has been placed
if [ -f $SSL_CONF_DESTINATION ]; then
    echo "MariaDB SSL config placed at $SSL_CONF_DESTINATION"
fi
