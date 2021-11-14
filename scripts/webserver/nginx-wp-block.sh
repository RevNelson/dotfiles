#!/bin/bash
#
# Nginx - new server block
# Modified from: https://gist.github.com/0xAliRaza/327ec99fff803417c5d06ba609255b49
#

FILENAME=$(basename "$0" .sh)

# Check for USERNAME and set it if not found
[[ -z ${USERNAME:-} ]] && USERNAME=${SUDO_USER:-$USER}

# Check for HOME_DIRECTORY and set it if not found
[[ -z ${HOME_DIRECTORY:-} ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)

[[ -z ${DOTBASE:-} ]] && DOTBASE=$HOME_DIRECTORY/.dotfiles

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-d} domain] [{-r} root_dir] [{-l} logs_path] [{-f} file_path]"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME -d api.${USERNAME}.com -r ${USERNAME}/api/wp/public)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-d} domain         -- Set fully qualified domain"
    echo "  {-r} root           -- Set root of public path (default: pwd)"
    echo "  {-l} logs_path      -- Set logs path (default: root_path/../)"
    echo "  {-f} file_path      -- Set file path (default: /etc/nginx/sites-available/DOMAIN)"
    exit 0
}

while getopts 'hd:r:l:' flag; do
    case "${flag}" in
    h)
        help
        exit 1
        ;;
    d) DOMAIN="${OPTARG}" ;;
    r) PUBLIC_PATH="${OPTARG}" ;;
    l) LOGS_PATH="${OPTARG}" ;;
    f) FILE_PATH="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
[[ -z ${DOMAIN} ]] && error $FILENAME "No domain specified."

# Set default variables
[[ -z ${PUBLIC_PATH:-} ]] && PUBLIC_PATH=$PWD
[[ -z ${LOGS_PATH:-} ]] && LOGS_PATH="$(dirname $PUBLIC_PATH)/logs"
[[ -z ${NGINX_AVAILABLE:-} ]] && NGINX_AVAILABLE="/etc/nginx/sites-available"
[[ -z ${FILE_PATH:-} ]] && FILE_PATH=$NGINX_AVAILABLE/$DOMAIN

# Create nginx config file
BLANK_WP_BLOCK=$DOTBASE/scripts/webserver/nginx-wp-block.conf
cp $BLANK_WP_BLOCK $FILE_PATH

sed -i "s/DOMAIN/${DOMAIN}/g" $FILE_PATH
sed -i "s/LOGS_PATH/${LOGS_PATH}/g" $FILE_PATH
sed -i "s/PUBLIC_PATH/${PUBLIC_PATH}/g" $FILE_PATH
