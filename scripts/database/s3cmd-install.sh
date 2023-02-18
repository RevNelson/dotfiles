#!/bin/bash

SCRIPT_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for USERNAME and set it if not found
[[ -z ${USERNAME:-} ]] && USERNAME=${SUDO_USER:-$USER}

# Check for HOME_DIRECTORY and set it if not found
[[ -z ${HOME_DIRECTORY:-} ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)

#############
# Functions #
#############

# Source function utils
. $HOME_DIRECTORY/.dotfiles/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: sudo $FILENAME   \\"
    echo -e "\n       Installs the latest version of s3cmd."
}

####################
# Script Variables #
####################

while getopts 'h' flag; do
    case $flag in
    h)
        usage_info
        exit 1
        ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

# Install dependencies
apt_quiet install python-setuptools

cd /tmp
wget $(curl -s https://api.github.com/repos/s3tools/s3cmd/releases/latest | grep 'browser_' | cut -d\" -f4) >/dev/null 2>&1

cd $HOME_DIRECTORY
tar xf /tmp/s3cmd-*.tar.gz >/dev/null 2>&1
cd s3cmd-*
python3 setup.py install >/dev/null 2>&1

# Clean up
cd $HOME_DIRECTORY
rm -rf s3cmd-*
rm -rf /tmp/s3cmd-*
