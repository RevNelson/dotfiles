#!/bin/bash

SCRIPT_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for USERNAME and set it if not found
[[ -z "$USERNAME" ]] && USERNAME=${SUDO_USER:-$USER}

# Check for HOME_DIRECTORY and set it if not found
[[ -z "$HOME_DIRECTORY" ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)

#############
# Functions #
#############

# Load utils (error, okay, run_as_root)
. $HOME_DIRECTORY/.dotfiles/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: sudo $FILENAME [{-d} domain] [{-p} project_path] [{-l} logs_path]  \\"
    echo "       $BLNK [{-u} user] [{-m} database_info] \\"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME -d api.${USERNAME}.com -p ${USERNAME}/api -m db_user:db_pass:db_name:host:ssl)"
}

help() {
    usage_info
    echo
    echo "  {-p} project_path   -- Set project_path - e.g. ${USERNAME}/api"
    echo "  {-d} domain         -- Set domain - e.g. api.${USERNAME}.com -- if not provided, Nginx block won't be created"
    echo "  {-l} logs_path      -- Set logs path (default: project_path/wp/logs/) -- only used for Nginx block"
    echo "  {-u} nginx_user     -- Set user for chmod on public folder (default: ${USERNAME})"
    echo "  {-m} database       -- Set database info as array - e.g. -m db_user:db_pass:db_name:host:ssl"
    echo "                         If no 5th element (ssl), SSL will not be set."
    exit 0
}

####################
# Script Variables #
####################

while getopts 'hp:d:l:u:m:' flag; do
    case $flag in
    h)
        help
        exit 1
        ;;
    p) PROJECT_PATH="${OPTARG}" ;;
    d) DOMAIN="${OPTARG}" ;;
    l) LOGS_PATH="${OPTARG}" ;;
    u) NGINX_USER="${OPTARG}" ;;
    m) IFS=: read -a DATABASE <<<"$OPTARG" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

[[ -z "$PROJECT_PATH" ]] && error "No project_path specified. Use -h for more information."

# Check DB data
db_error() {
    error "\nMust include ${1} in -m flag. e.g. $(magenta db_user:db_pass:db_name:host:ssl)"
}

if [ ! -z DATABASE ]; then
    DB_USER="${DATABASE[0]}"
    DB_PASS="${DATABASE[1]}"
    DB_NAME="${DATABASE[2]}"
    DB_HOST="${DATABASE[3]}"
    DB_SSL="${DATABASE[4]}"

    [[ -z "$DB_USER" ]] && db_error "DB_USER"
    [[ -z "$DB_PASS" ]] && db_error "DB_PASS"
    [[ -z "$DB_NAME" ]] && db_error "DB_NAME"
    [[ -z "$DB_HOST" ]] && db_error "DB_HOST"
fi

#############################
# Download latest Wordpress #
#############################

if [ ! -d /tmp/wordpress ]; then
    cd /tmp
    curl -sLO https://wordpress.org/latest.tar.gz >/dev/null
    tar xzf latest.tar.gz >/dev/null
fi

#####################
# Install Wordpress #
#####################

WP_BASE_DIR="${HOME_DIRECTORY}/${PROJECT_PATH}/wp"
WP_PUBLIC="${WP_BASE_DIR}/public"
PROJECT_NAME=$(echo ${PROJECT_PATH} | awk -F'/' '{print $1}')

# Create destination path if it doesn't exist
mkdir -p $WP_PUBLIC

# Move Wordpress to destination
cp -a /tmp/wordpress/. $WP_PUBLIC

# Assign ownership
chown -R "${USERNAME}:${USERNAME}" $WP_PUBLIC

cd $WP_BASE_DIR

# Move wp-config.php out of public folder for security.
mv public/wp-config-sample.php wp-config.php

# Add SSL option
sed -i "/^define( 'DB_NAME.*/i //define( 'MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL );\n" wp-config.php

###################
# Config database #
###################

DB_FILE=$WP_BASE_DIR/wp-config.php

if [ ! -z DATABASE ]; then
    if [ ! -z DB_SSL ]; then
        sed -i "/^define( 'DB_NAME/i define( 'MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL );\n" $DB_FILE
    fi

    sed -i "s/DB_NAME.*/DB_NAME', '${DB_NAME}' );/" $DB_FILE
    sed -i "s/DB_USER.*/DB_USER', '${DB_USER}' );/" $DB_FILE
    sed -i "s/DB_PASSWORD.*/DB_PASSWORD', '${DB_PASS}' );/" $DB_FILE
    sed -i "s/DB_HOST.*/DB_HOST', '${DB_HOST}' );/" $DB_FILE
fi

################
# Update salts #
################

. ${SCRIPT_ABSOLUTE_PATH}/wp-update-salts.sh

###############
# Nginx block #
###############

if [ ! -z "$DOMAIN" ]; then
    [[ -z NGINX_USER ]] && NGINX_USER=$USERNAME
    PUBLIC_PATH=$WP_PUBLIC
    . ${SCRIPT_ABSOLUTE_PATH}/nginx-add-block.sh
fi

# TODO - add NGINX block
