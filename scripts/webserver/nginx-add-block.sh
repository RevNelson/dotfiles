#!/bin/bash
NGINX_ADD_BLOCK_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#
# Nginx - new server block
# Modified from: https://gist.github.com/0xAliRaza/327ec99fff803417c5d06ba609255b49
#

FILENAME=$(basename "$0" .sh)

[[ -z ${USERNAME:-} ]] && USERNAME=${SUDO_USER:-$USER}

BLOCK_TYPE="wp"

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-d} domain] [{-r} root_dir] [{-l} logs_path]"
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
    echo "  {-t} block_type     -- Set block type (wp, static, pm2) (default: wp)"
    exit 0
}

while getopts 'hd:r:l:t:' flag; do
    case "${flag}" in
    h)
        help
        exit 1
        ;;
    d) DOMAIN="${OPTARG}" ;;
    r) PUBLIC_PATH="${OPTARG}" ;;
    l) LOGS_PATH="${OPTARG}" ;;
    t) BLOCK_TYPE="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
[[ -z ${DOMAIN} ]] && error $FILENAME "No domain specified."

# Variables
[[ -z ${PUBLIC_PATH:-} ]] && PUBLIC_PATH=$PWD
[[ -z ${LOGS_PATH:-} ]] && LOGS_PATH="$(dirname $PUBLIC_PATH)/logs"
NGINX_AVAILABLE='/etc/nginx/sites-available'
NGINX_ENABLED='/etc/nginx/sites-enabled'

# Make sure logs directory exists
mkdir -p $LOGS_PATH

# Changing permissions
chown -R www-data:www-data $PUBLIC_PATH

# Create nginx config file

# WP Block
if [ "$BLOCK_TYPE" = "wp" ]; then
    . $NGINX_ADD_BLOCK_ABSOLUTE_PATH/nginx-wp-block.sh -d $DOMAIN -r $PUBLIC_PATH -l $LOGS_PATH
fi

# Enable site by creating symbolic link
ln -s $NGINX_AVAILABLE/$DOMAIN $NGINX_ENABLED/$DOMAIN

# Restart
nginx -t
service nginx restart

# Secure domain with SSL
certbot --noninteractive --nginx --redirect --agree-tos -m "$(sudo -u $USERNAME git config --global user.email)" -d $DOMAIN

ok "Nginx block created for ${DOMAIN}, served from ${PUBLIC_PATH}"

# TODO - Check Nginx block for redirect using HTTP2
