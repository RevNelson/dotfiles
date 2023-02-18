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

OUTPUT_DIR="${HOME_DIRECTORY}/backups"
CURRENTDATE=$(date +"%Y-%m-%d")
OUTPUT_PATH="${OUTPUT_DIR}/alldb_${CURRENTDATE}.sql.bz2.enc"
KEY_PATH="/etc/mysql/mdbbackup-pub.key"

# Source function utils
. $DOTBASE/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-k} public-key-path] [{-o} output-path] \\"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME)"

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
    echo "  {-o} output-path        -- Set path for output of backup (default $OUTPUT_PATH)"
    exit 0
}

while getopts 'hko:' flag; do
    case "$flag" in
    h) help ;;
    k) KEY_PATH="${OPTARG}" ;;
    o) OUTPUT_PATH="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

# Dump all databases and directly zip and ecrypt the file.
mysqldump --routines --triggers --events --quick --single-transaction \
    --all-databases | bzip2 | openssl smime -encrypt -binary -text -aes256 \
    -out ${OUTPUT_PATH} -outform DER ${KEY_PATH} && chmod 600 ${OUTPUT_PATH}
