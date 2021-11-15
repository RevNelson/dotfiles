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
    echo "Usage: $FILENAME [{-b} backup-date] [{-d} database-names] [{-k} priveat-key-path] [{-s} s3-host] \\"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME -b 2021-07-01 -d ${USERNAME}_api:other_database -s example-host)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-b} backup-date        -- Set date of backup to restore from (i.e. YYYY-MM-DD) (REQUIRED)"
    echo "  {-d} database-names     -- Set name(s) for database to restore from backup (REQUIRED)"
    echo "  {-k} public-key-path    -- Path to private key for encrypted backups (default $KEY_PATH)"
    echo "  {-s} s3-host            -- Set hostname for S3 (required)"
    echo "  Public key will be deleted at the end of the script!"
    exit 0
}

while getopts 'hb:d:k:s:' flag; do
    case "${flag}" in
    b) BACKUP_DATE="${OPTARG}" ;;
    d) DATABASE_NAMES="${OPTARG}" ;;
    k) KEY_PATH="${OPTARG}" ;;
    s) S3_HOST_DB_BACKUP="${OPTARG}" ;;
    h) help ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

# Check for s3-host flag
if [ -z ${S3_HOST_DB_BACKUP:-} ]; then
    echo -e "\n$(red No s3-host provided.)\n"
    echo -e"Please pass the s3-host flag (i.e. $(magenta -s example-host)\n"
    help
fi

if [ -z $BACKUP_DATE:- ]; then
    echo "$(red Date of backup file required)"
    help
fi

BACKUP_FILENAME="alldb_${BACKUP_DATE}.sql.bz2.enc"
OUTPUT_PATH=/tmp/${BACKUP_FILENAME}

s3cmd get s3://${S3_HOST_DB_BACKUP}/${BACKUP_FILENAME} $OUTPUT_PATH

. $DOTBASE/scripts/database/mysql-restore.sh -i $OUTPUT_PATH -d ${DATABASE_NAMES} -k ${KEY_PATH}

rm $OUTPUT_PATH
