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

# Source function utils
. $DOTBASE/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-s} ssl-required] [{-u} db-user] [{-h} db-user-host] \\"
    echo "       $BLNK [{-p} db-user-password] [{-d} db-user-database-name] \\"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME -s -u $USERNAME -h 192.168.0.30 -p password1234 -d ${USERNAME}_wp)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-s} ssl-required        -- (Flag only) Require SSL when connecting."
    echo "  {-u} db-user             -- Set username for new mysql user"
    echo "  {-h} db-user-host        -- Set host IP for new mysql user"
    echo "  {-p} db-user-password    -- Set password for new mysql user"
    echo "  {-d} db-name             -- Set database name to grant access to for new mysql user"
    exit 0
}

while getopts 's:u:h:p:d:' flag; do
    case "$flag" in
    s) SSL=" REQUIRE SSL" ;;
    u) DB_USER="${OPTARG}" ;;
    h) DB_USER_HOST="${OPTARG}" ;;
    p) DB_USER_PASSWORD="${OPTARG}" ;;
    d) DB_USER_DATABASE="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

# Check for all required arguments
[[ -z ${DB_USER} ]] && {
    echo "No username provided."
    help
}
[[ -z ${DB_USER_HOST} ]] && {
    echo "No host for $DB_USER provided."
    help
}
[[ -z ${DB_USER_PASSWORD} ]] && {
    echo "No password for $DB_USER@$DB_USER_HOST provided."
    help
}
[[ -z ${DB_USER_DATABASE} ]] && {
    echo "No database for $DB_USER@$DB_USER_HOST provided."
    help
}

mysql -e \
    "GRANT ALL PRIVILEGES ON ${DB_USER_DATABASE}.* TO '${DB_USER}'@'${DB_USER_HOST}' IDENTIFIED BY '${DB_USER_PASSWORD}'${SSL};"

echo -e "\n$(green User $DB_USER@$DB_USER_HOST created and granted access to DB $DB_USER_DATABASE)\n"
