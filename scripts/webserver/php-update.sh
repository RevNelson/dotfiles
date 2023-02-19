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

apt_quiet update && apt_quiet install php8.1-fpm -y

# Install PHP extensions for WP
apt_quiet install php8.1-bcmath php8.1-curl php8.1-gd php8.1-igbinary php8.1-imagick php8.1-intl \
  php8.1-mbstring php8.1-mysql php8.1-redis php8.1-soap php8.1-xml php8.1-xmlrpc php8.1-zip

# Add webserver PHP settings overrides

echo "Adding optimized PHP settings..."

PHP_INI="$DOTBASE/scripts/webserver/php/php.ini"
PHP_FPM_CONF="$DOTBASE/scripts/webserver/php/php-fpm.conf"

PHP_BASE_CONFIG_DESTINATION="/etc/php/8.1/fpm/"

if [ -f $PHP_INI ]; then
  cp $PHP_INI $PHP_BASE_CONFIG_DESTINATION
fi

if [ -f $PHP_FPM_CONF ]; then
  cp $PHP_FPM_CONF $PHP_BASE_CONFIG_DESTINATION
fi

echo "Adding PHP overrides..."

USER_PHP_FILE="$DOTBASE/scripts/webserver/php/overrides.ini"
USER_PHP_DESTINATION="/etc/php/8.1/fpm/conf.d/99-webserver-overrides.ini"

if [ -f $USER_PHP_FILE ]; then
  cp $USER_PHP_FILE $USER_PHP_DESTINATION
fi

if [ -f $USER_PHP_DESTINATION ]; then
  echo "PHP overrides placed at $USER_PHP_DESTINATION"
fi

echo "Restarting PHP..."

systemctl restart php8.1-fpm

echo "PHP is configured."
