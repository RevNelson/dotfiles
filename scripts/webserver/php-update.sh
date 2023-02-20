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

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

# Source function utils
. $DOTBASE/functions/utils.sh

#
##
###
##########
# Script #
##########
###
##
#

echo "Adding PHP repository..."

apt_quiet install ca-certificates apt-transport-https software-properties-common -y
add-apt-repository --yes ppa:ondrej/php >/dev/null

echo "Installing PHP and plugins..."

apt_quiet update

versions=(
    8.0
    8.1
    8.2
)

modules=(
    bcmath
    curl
    gd
    igbinary
    imagick
    intl
    mbstring
    mysql
    redis
    soap
    xml
    xmlrpc
    zip
)

# install each version with corresponding modules
for version in "${versions[@]}"; do
    apt_quiet install "php$version-fpm"
    for module in "${modules[@]}"; do
        apt_quiet install "php$version-$module"
    done
done

echo "Adding PHP overrides..."

for version in "${versions[@]}"; do
    USER_PHP_FILE="$DOTBASE/scripts/webserver/php/overrides.ini"
    USER_PHP_DESTINATION="/etc/php/$version/fpm/conf.d/99-overrides.ini"

    if [ -f $USER_PHP_FILE ]; then
        cp $USER_PHP_FILE $USER_PHP_DESTINATION
    fi

    if [ -f $USER_PHP_DESTINATION ]; then
        echo "PHP $version overrides placed at $USER_PHP_DESTINATION"
    fi
done

echo "Restarting PHP..."

for version in "${versions[@]}"; do
    systemctl restart "php$version-fpm"
done

echo "PHP is configured."
