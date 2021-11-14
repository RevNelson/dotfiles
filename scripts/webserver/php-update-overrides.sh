#!/bin/bash

# Check for HOME_DIRECTORY and set it if not found
[[ -z ${HOME_DIRECTORY:-} ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
[[ -z ${DOTBASE:-} ]] && DOTBASE=$HOME_DIRECTORY/.dotfiles

# Source function utils
. $DOTBASE/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

USER_PHP_FILE="$DOTBASE/scripts/webserver/php.ini"
USER_PHP_DESTINATION="/etc/php/8.0/fpm/conf.d/99-webserver-overrides.ini"

if [ -f $USER_PHP_FILE ]; then
    cp $USER_PHP_FILE $USER_PHP_DESTINATION
fi

if [ -f $USER_PHP_DESTINATION ]; then
    echo "PHP overrides placed at $USER_PHP_DESTINATION"
fi
