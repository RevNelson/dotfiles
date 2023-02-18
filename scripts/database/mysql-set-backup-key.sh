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

KEY_PATH=$HOME_DIRECTORY/backup.key
DESTINATION="/etc/mysql/mdbbackup-pub.key"

# Source function utils
. $DOTBASE/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-k} private-key-path] [{-d} destination] \\"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME) after placing private key at $KEY_PATH"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-k} private-key-path    -- Path to private key (default $KEY_PATH)"
    echo "  {-d} destination         -- Set path to place public key (default $DESTINATION)"
    echo -e "\n$(red Private key file will be removed after placing public key.)\n"
    exit 0
}

while getopts 'hk:d:' flag; do
    case "$flag" in
    h) help ;;
    k) KEY_PATH="${OPTARG}" ;;
    d) DESTINATION="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

if [ -f $KEY_PATH ]; then
    if [ -z ${ENCRYPTION_PASS:-} ]; then
        echo "Encryption password: "
        read -s ENCRYPTION_PASS
    fi
    openssl req -x509 -passin pass:$ENCRYPTION_PASS -nodes -key $KEY_PATH -out $DESTINATION -subj "/C=US/ST=CA/L=LA/O=Dis/CN=MariaDB-backup"
    rm $KEY_PATH
else
    echo "$(red No private key found.)"
    help
fi
