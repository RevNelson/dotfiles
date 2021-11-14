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

if [ -f $DOTBASE/usertype.sh ]; then
    . $DOTBASE/usertype.sh
fi

KEY_PATH=$HOME_DIRECTORY/backups.key

# Source function utils
. $DOTBASE/functions/utils.sh

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
NGINX_CONF=$NGINX_AVAILABLE/$DOMAIN

# Make sure logs directory exists
mkdir -p $LOGS_PATH

# Changing permissions
chown -R www-data:www-data $PUBLIC_PATH

# Create basic nginx config file to pass certbot checks
BLANK_BLOCK=$DOTBASE/scripts/webserver/nginx-block-80.conf
cp $BLANK_BLOCK $NGINX_CONF

sed -i "s/DOMAIN/${DOMAIN}/g" $NGINX_CONF
sed -i "s|LOGS_PATH|${LOGS_PATH}|g" $NGINX_CONF
sed -i "s|PUBLIC_PATH|${PUBLIC_PATH}|g" $NGINX_CONF

# Secure domain with SSL
certbot --noninteractive --nginx --no-redirect --agree-tos --no-eff-email -m "$(sudo -u $USERNAME git config --global user.email)" -d $DOMAIN

# WP Block
if [ "$BLOCK_TYPE" = "wp" ]; then
    SSL_BLOCK=$DOTBASE/scripts/webserver/nginx-wp-block-ssl.conf
fi

# Copy SSL block
cp $SSL_BLOCK $NGINX_CONF

sed -i "s/DOMAIN/${DOMAIN}/g" $NGINX_CONF
sed -i "s|LOGS_PATH|${LOGS_PATH}|g" $NGINX_CONF
sed -i "s|PUBLIC_PATH|${PUBLIC_PATH}|g" $NGINX_CONF

if [ -f ${NGINX_CONF} ]; then
    # Enable site by creating symbolic link
    ln -s $NGINX_CONF $NGINX_ENABLED/$DOMAIN
fi

# Restart
nginx -t
service nginx restart

ok "Nginx block created for ${DOMAIN}, served from ${PUBLIC_PATH}"
