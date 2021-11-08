#!/bin/bash
NGINX_UPDATE_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for USERNAME and set it if not found
[[ -z "$USERNAME" ]] && USERNAME=${SUDO_USER:-$USER}

# Check for HOME_DIRECTORY and set it if not found
[[ -z "$HOME_DIRECTORY" ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
[[ -z "$DOTBASE" ]] && DOTBASE=$HOME_DIRECTORY/.dotfiles

#############
# Functions #
#############

# Source function utils
. $DOTBASE/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

# Load utils (run_as_root, cmd_exists, apt_)
. $DOTBASE/.dotfiles/functions/utils.sh

NGINX_CONF=/etc/nginx/nginx.conf
NGINX_CONF_TEMPLATE="$NGINX_UPDATE_ABSOLUTE_PATH/nginx.conf"

if ! cmd_exists nginx; then
    apt_quiet install nginx-full certbot python3-certbot-nginx -y
    ufw allow "Nginx Full" >/dev/null >&2

    # Backup Nginx config
    NGINX_CONF_BACKUP=/etc/nginx/nginx_backup.conf
    if [[ ! -f $NGINX_CONF_BACKUP ]]; then
        cp $NGINX_CONF $NGINX_CONF_BACKUP
    fi
fi

apt_quiet update && apt_quiet upgrade -y

CPU_COUNT="$(grep processor /proc/cpuinfo | wc -l)"

# Copy config template
cp $NGINX_CONF_TEMPLATE $NGINX_CONF

# Add dynamic config
sed -i "s/worker_processes.*/worker_processes ${CPU_COUNT};/" $NGINX_CONF
sed -i "s/worker_cpu_affinity.*/worker_cpu_affinity ${CPU_COUNT};/" $NGINX_CONF
sed -i "s/^user .*/user ${USERNAME};/" $NGINX_CONF

echo "Nginx configured for user: ${USERNAME}"
