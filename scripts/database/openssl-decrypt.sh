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

# Default variables
KEY_PATH=$HOME_DIRECTORY/backup.key

# Source function utils
. $DOTBASE/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-i} input_path] [{-o} output_path] [{-k} key_path]"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME -i alldb.sql.bz2.enc -o alldb.sql.bz2)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-i} input_path          -- Set path to input file (required)."
    echo "  {-o} output_path         -- Set path to output file (required)."
    echo "  {-k} key_path            -- Set path to private key (default $KEY_PATH)"
    echo -e "\n Make sure to create a file with private key before running this script."
    echo -e "$(red Private key file will be removed upon decrypting input.)\n"
    exit 0
}

while getopts 'hiok:' flag; do
    case "$flag" in
    h) help ;;
    i) FILE_PATH="${OPTARG}" ;;
    o) OUTPUT_PATH="${OPTARG}" ;;
    k) KEY_PATH="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

if [ -z "$FILE_PATH" ] || [ -z "$OUTPUT_PATH" ]; then
    echo "$(red File path and output path are required)"
    help
fi

openssl smime -decrypt -in $FILE_PATH -binary -inform DEM -inkey $KEY_PATH -out $OUTPUT_PATH
rm $KEY_PATH
