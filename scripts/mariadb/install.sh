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

HOME_DIRECTORY="/home/${USERNAME}"
DIRECTORY=$HOME_DIRECTORY/mariadb

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

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-d} directory] \\"
    echo -e "\n        e.g. $(magenta $FILENAME -d $DIRECTORY)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-d} directory (Default is: $DIRECTORY)"
    echo "  {-h} help"
    exit 0
}

####################
# Script Variables #
####################

while getopts 'hk:s:e:c:' flag; do
    case $flag in
    h) help ;;
    d) DIRECTORY="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

#
##
###
##########
# Script #
##########
###
##
#

print_section "Installing MariaDB..."

mkdir -p $DIRECTORY

echo "Creating backup script..."
read -p "Backup directory: " USERNAME
[[ -z ${USERNAME} ]] && {
    echo "Must provide a username for the main user of this droplet with privileges."
    exit 1
}

echo "Password for $USERNAME: "
read -s USER_PASSWORD
[[ -z ${USER_PASSWORD} ]] && {
    echo "Must provide a password for $USERNAME."
    exit 1
}

BACKUP_DIR=$DIRECTORY/backups/files
S3_BUCKET_NAME=nelson.tech-db
S3_DIRECTORY_NAME=backups
DAYS_TO_KEEP=30
MYSQL_USER=root
MYSQL_PASSWORD=DWqzrHmQrYMU366FFmzD
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump

echo "$(green MariaDB is now installed.)"
