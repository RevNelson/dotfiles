#!/bin/bash

S3CMD_VERSION="2.2.0"

SCRIPT_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for USERNAME and set it if not found
[[ -z "$USERNAME" ]] && USERNAME=${SUDO_USER:-$USER}

# Check for HOME_DIRECTORY and set it if not found
[[ -z "$HOME_DIRECTORY" ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)

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
    echo "Usage: sudo $FILENAME [{-d} domain] [{-p} project_path] [{-l} logs_path]  \\"
    echo -e "\n       $BLNK e.g. $(magenta sudo ./$FILENAME -v ${S3CMD_VERSION})"
}

help() {
    usage_info
    echo
    echo "  {-v} version   -- Set version of s3cmd to install (default: ${S3CMD_VERSION}"
    exit 0
}

####################
# Script Variables #
####################

while getopts 'hv:' flag; do
    case $flag in
    h)
        help
        exit 1
        ;;
    v) S3CMD_VERSION="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

apt_quiet install python-setuptools -y
cd /tmp
curl -LO "https://github.com/s3tools/s3cmd/releases/download/v${S3CMD_VERSION}/s3cmd-${S3CMD_VERSION}.tar.gz"
cd $HOME_DIRECTORY
tar xf /tmp/s3cmd-*.tar.gz
cd s3cmd-*
python setup.py install
