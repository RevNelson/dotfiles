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

search_dir=/etc/caddy
for entry in "$search_dir"/*; do
  caddy fmt $entry --overwrite
done
