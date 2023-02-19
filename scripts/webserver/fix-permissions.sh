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

FILENAME=$(basename "$0" .sh)

WEBSERVER_DROPLET_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTING_PATH=$PWD

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
. $HOME_DIRECTORY/.dotfiles/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-s} site-name] \\"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME -s api.example.com)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

error() {
    echo -e "$FILENAME: $*" >&2
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-s} site-name     -- Site name to apply permission fix to."
    exit 0
}

#
##
###
################
# Script Flags #
################
###
##
#

while getopts 'hs:d:' flag; do
    case "$flag" in
    h) help ;;
    s) SITE_NAME="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

# Check for all required arguments
[[ -z ${SITE_NAME:-} ]] && {
    echo "Must provide the site name."
    help
}

#
##
###
##########
# Script #
##########
###
##
#

cd $HOME_DIRECTORY/sites/$SITE_NAME/files

chown -R $USERNAME public
chmod -R 755 public
chown -R www-data public/content/uploads
