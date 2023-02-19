#!/bin/bash

#
##
###
#############
# Variables #
#############
###
##
#

NGINX_UPDATE_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for USERNAME and set it if not found
[[ -z ${USERNAME:-} ]] && USERNAME=${SUDO_USER:-$USER}

# Check for HOME_DIRECTORY and set it if not found
[[ -z ${HOME_DIRECTORY:-} ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
[[ -z ${DOTBASE:-} ]] && DOTBASE=$HOME_DIRECTORY/.dotfiles

#
##
###
#############
# Functions #
#############
###
##
#

# Source function utils
. $DOTBASE/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

#
##
###
##########
# Script #
##########
###
##
#

echo "Installing Nginx..."

NGINX_FOLDER=/etc/nginx
NGINX_TEMPLATE_MIME_TYPE="$NGINX_UPDATE_ABSOLUTE_PATH/nginx/mime.types"
NGINX_TEMPLATE_CONFIG="$NGINX_UPDATE_ABSOLUTE_PATH/nginx/nginx.conf"
NGINX_TEMPLATE_SITES="$NGINX_UPDATE_ABSOLUTE_PATH/nginx/sites-available"

if ! cmd_exists nginx; then
    apt_quiet install nginx-full certbot python3-certbot-nginx 2>&1
    ufw allow "Nginx Full" >/dev/null

    echo "Backing up default Nginx configs..."
    # Backup Nginx configs
    NGINX_FOLDER_BACKUP=$NGINX_FOLDER/backup/
    if [[ ! -f $NGINX_FOLDER_BACKUP ]]; then
        mkdir $NGINX_FOLDER_BACKUP
        cp $NGINX_TEMPLATE_MIME_TYPE $NGINX_FOLDER_BACKUP
        cp $NGINX_TEMPLATE_CONFIG $NGINX_FOLDER_BACKUP
        cp -r $NGINX_TEMPLATE_SITES $NGINX_FOLDER_BACKUP
    fi
fi

echo "Adding optimized Nginx configs..."
# Copy config templates (escape cp to overwrite without prompt)
\cp $NGINX_TEMPLATE_MIME_TYPE $NGINX_FOLDER/
\cp $NGINX_TEMPLATE_CONFIG $NGINX_FOLDER/
\cp -r $NGINX_TEMPLATE_SITES $NGINX_FOLDER/

# Remove links from sites-enabled
rm -rf $NGINX_FOLDER/sites-enabled/*

# Link default server block
ln -s $NGINX_FOLDER/sites-available/default $NGINX_FOLDER/sites-enabled/

# Add dynamic config
# CPU_COUNT="$(grep processor /proc/cpuinfo | wc -l)"
# sed -i "s/worker_processes.*/worker_processes ${CPU_COUNT};/" $NGINX_FOLDER

echo "Nginx configured."
