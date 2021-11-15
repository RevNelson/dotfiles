#!/bin/bash

FILENAME=$(basename "$0" .sh)

# Check for USERNAME and set it if not found
[[ -z ${USERNAME:-} ]] && USERNAME=${SUDO_USER:-$USER}

# Check for HOME_DIRECTORY and set it if not found
[[ -z ${HOME_DIRECTORY:-} ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)

[[ -z ${DOTBASE:-} ]] && DOTBASE=$HOME_DIRECTORY/.dotfiles

if [ -f $DOTBASE/usertype.sh ]; then
    . $DOTBASE/usertype.sh
fi

CURRENTDATE=$(date +"%Y-%m-%d")
OUTPUT_NAME="alldb_${CURRENTDATE}.sql.bz2.enc"
KEY_PATH="/etc/mysql/mdbbackup-pub.key"

# Source function utils
. $DOTBASE/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-k} public-key-path] [{-o} output-name] [{-s} s3-host] \\"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME -s example-host)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-k} public-key-path    -- Path to public key (default $KEY_PATH)"
    echo "  {-o} output-name        -- Set name for backup (default $OUTPUT_NAME)"
    echo "  {-s} s3-host            -- Set hostname for S3 (required)"
    exit 0
}

while getopts 'hk:o:s:' flag; do
    case "${flag}" in
    k) KEY_PATH="${OPTARG}" ;;
    o) OUTPUT_PATH="${OPTARG}" ;;
    s) S3_HOST_DB_BACKUP="${OPTARG}" ;;
    h) help ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

if [ ! -f /root/.s3cfg ]; then
    echo -e "\n$(red No .s3cfg found for sudo user.)\n"
    echo -e"Please run:\n"
    echo "$(magenta s3cmd --configure)"
    echo -e "\nand then link the config to root with:\n"
    echo -e "$(magenta sudo ln -s $HOME_DIRECTORY/.s3cmd /root/)\n"
    exit 1
fi

# Check for s3-host flag
if [ -z ${S3_HOST_DB_BACKUP:-} ]; then
    echo -e "\n$(red No s3-host provided.)\n"
    echo -e"Please pass the s3-host flag (i.e. $(magenta -s example-host)\n"
    exit 1
fi

# Dump all databases and directly zip and ecrypt the file.
mysqldump --routines --triggers --events --quick --single-transaction \
    --all-databases | bzip2 | openssl smime -encrypt -binary -text -aes256 \
    -outform DER ${KEY_PATH} | s3cmd put - s3://${S3_HOST_DB_BACKUP}/${OUTPUT_NAME}
