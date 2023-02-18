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

SSL_CA=/etc/mysql/ssl/cacert.pem
SSL_CERT=/etc/mysql/ssl/client-cert.pem
SSL_KEY=/etc/mysql/ssl/client-key.pem

DEFAULT_DESTINATION_DIRECTORY=/etc/mysql/ssl

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
    echo "Usage: $FILENAME [{-s} source-directory] [{-d} destination-directory] \\"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME -s /home/[username]/certs -d /etc/mysql/ssl)"
    echo -e "\n        e.g. $(red WARNING: Source certs will be removed at the end of the script.)"

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
    echo "  {-s} source-directory       -- Set directory where certs currently are."
    echo "  {-d} destination-directory  -- Set directory where certs should be moved to (default: ${DEFAULT_DESTINATION_DIRECTORY})."
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

while getopts 'hsd:' flag; do
    case "$flag" in
    h) usage_info ;;
    s) SOURCE_DIRECTORY="${OPTARG}" ;;
    d) DESTINATION_DIRECTORY="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

# Check for all required arguments
[[ -z ${SOURCE_DIRECTORY:-} ]] && {
    echo "Must provide the source directory for the certs."
    help
}
[[ -z ${DESTINATION_DIRECTORY:-} ]] && {
    echo "No user provided. Defaulting to $DEFAULT_DESTINATION_DIRECTORY."
    DESTINATION_DIRECTORY=$DEFAULT_DESTINATION_DIRECTORY
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

if [ -f "$SOURCE_DIRECTORY/cacert.pem" ]; then
    cp "$SOURCE_DIRECTORY/cacert.pem" $DESTINATION_DIRECTORY
    echo "cacert.pem copied."
fi

if [ -f "$SOURCE_DIRECTORY/client-cert.pem" ]; then
    cp "$SOURCE_DIRECTORY/client-cert.pem" $DESTINATION_DIRECTORY
    echo "client-cert.pem copied."
fi

if [ -f "$SOURCE_DIRECTORY/client-key.pem" ]; then
    cp "$SOURCE_DIRECTORY/client-key.pem" $DESTINATION_DIRECTORY
    echo "client-key.pem copied."
fi

rm -rf $SOURCE_DIRECTORY
echo "Source directory has been removed."
