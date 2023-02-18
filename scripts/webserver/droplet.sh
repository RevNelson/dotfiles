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

. $DOTBASE/scripts/webserver/mariadb-client.sh

#################
# Install Nginx #
#################

. $DOTBASE/scripts/webserver/nginx-update.sh

###############
# Install PHP #
###############

echo "Installing PHP..."
. $DOTBASE/scripts/webserver/php-update.sh

###############
# Install NVM #
###############

NVM_VERSION="0.39.3"

echo "Installing NVM v$NVM_VERSION..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash

# Install node
NODE_VERSION="18"

echo "Installing latest LTS node version..."
apt_quiet install build-essential

echo "Installing latest LTS node version..."
echo "\n$(magenta 'This may take a long time if it needs to be compiled.')"
nvm install --lts

echo "Installing global node packages..."
npm install -g yarn encoding

##################
# Install WP-CLI #
##################

echo "Installing WP-CLI..."
cd /tmp
curl -S -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /tmp/wp-cli.phar
mv /tmp/wp-cli.phar /usr/local/bin/wp
mkdir -p /var/www/.wp-cli/cache
chown -R www-data:www-data /var/www/.wp-cli/cache

####################
# Install Composer #
####################

echo "Installing Composer..."
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer

#########################################################

echo "Performing final package updates..."
apt_quiet update && apt_quiet upgrade

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
