#!/bin/bash

WEBSERVER_DROPLET_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTING_PATH=$PWD

# Source function utils
. $WEBSERVER_DROPLET_ABSOLUTE_PATH/../../functions/utils.sh

####################
# Script Variables #
####################

read -p "Username: " USERNAME
[[ -z ${USERNAME} ]] && {
    echo "Must provide a username for the main user of this droplet with privileges."
    exit 1
}

echo "Password for $USERNAME: "
read -s USER_PASSWORD
[[ -z ${USER_PASSWORD} ]] && {
    echo "Must provide a password for $USERNAME."
    exit 1
}

read -p "SSH Port (Press Enter for 22): " SSH_PORT

read -p "Private Database Server IP: " DATABASE_IP
[[ -z ${DATABASE_IP} ]] && {
    echo "Must provide the private IP of the database server droplet."
    exit 1
}
[[ -z ${SSH_PORT} ]] && export SSH_PORT=22

read -p "Is this a devserver? [y/n]: " IS_DEVSERVER

export HOME_DIRECTORY="/home/${USERNAME}"

if said_yes $IS_DEVSERVER; then
    export USERTYPE="devserver"
else
    export USERTYPE="webserver"
fi

##############################
# Initialize generic droplet #
##############################

. $WEBSERVER_DROPLET_ABSOLUTE_PATH/../generic-droplet-provision.sh ${USERNAME} ${USER_PASSWORD} ${SSH_PORT}

echo -e "\n#############################################"
echo "Performing webserver specific provisioning..."
echo -e "#############################################\n"

DOTBASE=$HOME_DIRECTORY/.dotfiles

# Add database server to hosts file
echo "${DATABASE_IP} database-server" >>/etc/hosts

###################
# Install MariaDB #
###################

echo "Installing MariaDB Client..."
. $DOTBASE/scripts/webserver/mariadb-client.sh

#################
# Install Nginx #
#################

echo "Installing Nginx..."
. $DOTBASE/scripts/webserver/nginx-update.sh

###############
# Install PHP #
###############

echo "Installing PHP..."
apt_quiet install ca-certificates apt-transport-https software-properties-common -y
add-apt-repository --yes ppa:ondrej/php >/dev/null
apt_quiet update && apt_quiet install php8.0-fpm -y
systemctl restart php8.0-fpm

# Install PHP extensions for WP
apt_quiet install php-mysql php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip -y

# Add webserver PHP settings overrides
. $DOTBASE/scripts/webserver/php-update-overrides.sh

##################
# Install WP-Cli #
##################

cd /tmp
curl -S -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /tmp/wp-cli.phar
mv /tmp/wp-cli.phar /usr/local/bin/wp
mkdir -p /var/www/.wp-cli/cache
chown -R www-data:www-data /var/www/.wp-cli/cache

# Performing final package updates
apt_quiet update && apt_quiet upgrade -y

su - $USERNAME

echo -e "\n################################"
echo "Webserver provisioning complete!"
echo -e "################################\n"

# Print public keys
echo "Root public SSH key: "
cat "/root/.ssh/id_ed.pub"
echo -e "\n${USERNAME} public SSH key: "
cat "${HOME_DIRECTORY}/.ssh/id_ed.pub"

echo -e "\n--------------------------------\n"
echo -e "\nAdd SSH to github."
echo -e "\nRun wp-install.sh for each wordpress project."

# Show help for wp-install
$DOTBASE/scripts/webserver/wp-install.sh -h

# TODO Setup droplet to use DO Spaces
