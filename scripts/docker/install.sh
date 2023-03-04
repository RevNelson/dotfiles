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

#
##
###
#############
# Functions #
#############
###
##
#

[[ -z ${DOTBASE:-} ]] && DOTBASE=$HOME/.dotfiles

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

print_section 'Installing Docker...'

echo "Updating apt sources..."
apt_quiet update

echo "Installing dependencies..."
apt_quiet install apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

echo "Adding docker signed keys to apt..."
KEYRINGS_DIR=/etc/apt/keyrings
KEY_FILENAME=$KEYRINGS_DIR/docker.gpg
mkdir -m 0755 -p $KEYRINGS_DIR
rm -f $KEY_FILENAME
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o $KEY_FILENAME

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null

apt_quiet update

echo "Installing docker..."
apt_quiet install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Setting docker to be run without root by ${USERNAME}..."
usermod -aG docker ${USERNAME}
