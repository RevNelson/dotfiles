#!/bin/bash

# Check for USERNAME and set it if not found
[[ -z "$USERNAME" ]] && USERNAME=${SUDO_USER:-$USER}

# Check for HOME_DIRECTORY and set it if not found
[[ -z "$HOME_DIRECTORY" ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
[[ -z "$DOTBASE" ]] && DOTBASE=$HOME_DIRECTORY/.dotfiles

# Set MariaDB bind address if given
if [ -z "$1" ]; then
    [[ -z "$PRIVATE_IP" ]] && PRIVATE_IP=0.0.0.0
else
    PRIVATE_IP=$1
fi

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
        apt_quiet update && apt_quiet install mariadb-server mariadb-backup -y
        rm mariadb_repo_setup
    else
        echo "Error downloading MariaDB repo setup file. Please run mariadb-setup again."
    fi

    ufw allow mysql

fi

# Seed server config file for SSL
SSL_CONF_FILE="$DOTBASE/scripts/database/mariadb-server.cnf"
SSL_CONF_DESTINATION="/etc/mysql/mariadb.conf.d/99-server-ssl.cnf"

if [ -f $SSL_CONF_FILE ]; then
    cp $SSL_CONF_FILE $SSL_CONF_DESTINATION
fi

# Check that file has been placed
if [ -f $SSL_CONF_DESTINATION ]; then
    sed -i "s/bind-address.*/bind-address = ${PRIVATE_IP}/g" $SSL_CONF_DESTINATION
    echo "MariaDB SSL config placed at $SSL_CONF_DESTINATION"
fi
