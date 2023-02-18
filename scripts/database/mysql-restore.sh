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

# Source function utils
. $DOTBASE/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-i} input-path] [{-d} database-names] [{-k} priveat-key-path] \\"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME -i $HOME_DIRECTORY/backup.sql.bz2.enc -d ${USERNAME}_api:other_database -k $KEY_PATH)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-i} input-path         -- Set path for backup file (REQUIRED)"
    echo "  {-d} database-names     -- Set name(s) for database to restore from backup (REQUIRED)"
    echo "  {-k} public-key-path    -- Path to private key for encrypted backups (default $KEY_PATH)"
    echo "  Public key will be deleted at the end of the script!"
    exit 0
}

while getopts 'hi:d:k:' flag; do
    case "$flag" in
    h) help ;;
    i) INPUT_PATH="${OPTARG}" ;;
    d) IFS=: read -a DATABASE_NAMES <<<"$OPTARG" ;;
    k) KEY_PATH="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

if [ -z "$INPUT_PATH" ]; then
    echo "$(red Input path of backup file required)"
    help
fi

# Check if input file is encrypted
if [[ $INPUT_PATH == *.enc ]]; then
    # Need to decrypt
    if [ -z "$KEY_PATH"]; then
        echo "$(red Private key is required to decrypt encrypted backups.)"
        help
    else
        # Store new path to remove decrypted file at end of script.
        NEW_INPUT=${INPUT_PATH::-4}

        . $DOTBASE/scripts/database/openssl-decrypt.sh -k $KEY_PATH -i $INPUT_PATH -o $NEW_INPUT

        # Update input path with decrypted file for rest of script.
        INPUT_PATH=$NEW_INPUT

        DECRYPTED_BACKUP=$NEW_INPUT
    fi
fi

if [ -z ${DATABASE_NAMES:-} ]; then
    read -p "Do you really want to restore ALL databases from the backup file? [y/n] " BACKUP_ALL
    if ! said_yes $BACKUP_ALL; then
        read -p "Enter database name(s) to restore or press CTRL+C to exit script: " DATABASE_NAMES
    fi
fi

# Check if input file is compressed
if [[ $INPUT_PATH == *.bz2 ]]; then
    if [ -z ${BACKUP_ALL:-}]; then
        for DATABASE_NAME in "${DATABASE_NAMES[@]}"; do
            bunzip2 <$INPUT_PATH | mysql --one-database $DATABASE_NAME
        done
    else
        if said_yes $BACKUP_ALL; then
            bunzip2 <$INPUT_PATH | mysql
            # Flush privileges to apply restored users
            mysql -e "FLUSH PRIVILEGES;"
        fi
    fi
fi

# Remove decrypted backup and private key for security
[[ ! -z ${DECRYPTED_BACKUP:-} ]] && rm $DECRYPTED_BACKUP

rm $KEY_PATH
