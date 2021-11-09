#!/bin/bash
#
# Nginx - new server block
# Modified from: https://gist.github.com/0xAliRaza/327ec99fff803417c5d06ba609255b49
#

FILENAME=$(basename "$0" .sh)

USERNAME=${SUDO_USER:-$USER}

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-d} domain] [{-r} root_dir] \\"
    echo "       $BLNK [{-l} logs_path] [{-u} user] \\"
}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

error() {
    echo -e "$FILENAME: $*" >&2
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-d} domain         -- Set fully qualified domain"
    echo "  {-r} root           -- Set root of public path (default: pwd)"
    echo "  {-l} logs_path      -- Set logs path (default: root_path/../)"
    echo "  {-u} nginx_user     -- Set user for chmod on public folder (default: ${USERNAME})"
    exit 0
}

while getopts 'hd:l:r:u:' flag; do
    case "${flag}" in
    h)
        help
        exit 1
        ;;
    d) DOMAIN="${OPTARG}" ;;
    l) LOGS_PATH="${OPTARG}" ;;
    r) PUBLIC_PATH="${OPTARG}" ;;
    u) NGINX_USER="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
[[ -z ${DOMAIN} ]] && error "No domain specified."
[[ -z "$PUBLIC_PATH" ]] && PUBLIC_PATH=$PWD
[[ -z "$LOGS_PATH" ]] && LOGS_PATH="$(dirname $PUBLIC_PATH)/logs"
[[ -z "$NGINX_USER" ]] && NGINX_USER=$USERNAME

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green

# Variables
NGINX_AVAILABLE='/etc/nginx/sites-available'
NGINX_ENABLED='/etc/nginx/sites-enabled'

# Make sure logs directory exists
mkdir -p $LOGS_PATH

# Create nginx config file
cat >$NGINX_AVAILABLE/$DOMAIN <<EOF

server {
    listen 80 http2;

    server_name ${DOMAIN};

    access_log ${LOGS_PATH}/access.log;
    error_log ${LOGS_PATH}/error.log;

    root        ${PUBLIC_PATH};

    index index.html index.htm index.php index.nginx-debian.html;

    location / {
        try_files $uri $uri/ /index.php?$args;

    }
    location ~ \.php$ {
#        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.0-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }

    # default-src 'self' https://*.google-analytics.com https://*.googleapis.com https://*.gstatic.com https://*.gravatar.com https://*.w.org data: 'unsafe-inline' 'unsafe-eval';

}
EOF

# Secure domain with SSL
certbot --noninteractive --nginx --redirect --agree-tos -m "$(sudo -u $USERNAME git config --global user.email)" -d $DOMAIN

# Changing permissions
chown -R $NGINX_USER:$NGINX_USER $PUBLIC_PATH

# Enable site by creating symbolic link
ln -s $NGINX_AVAILABLE/$DOMAIN $NGINX_ENABLED/$DOMAIN

# Restart
nginx -t
service nginx restart

ok "Nginx block created for ${DOMAIN}, served from ${PUBLIC_PATH}"

# TODO - Check Nginx block for redirect using HTTP2
