#!/bin/bash

WEBSERVER_DROPLET_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTING_PATH=$PWD

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

export HOME_DIRECTORY="/home/${USERNAME}"

##############################
# Initialize generic droplet #
##############################

. $WEBSERVER_DROPLET_ABSOLUTE_PATH/../generic-droplet-provision.sh ${USERNAME} ${USER_PASSWORD} ${SSH_PORT}

echo -e "\n#############################################"
echo "Performing webserver specific provisioning..."
echo -e "#############################################\n"

DOTBASE=$HOME_DIRECTORY/.dotfiles

# Make usertype.sh
USERTYPE_PATH=$DOTBASE/usertype.sh
cat >${USERTYPE_PATH} <<EOF
export USERTYPE="webserver"
EOF

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

#####################
# Install Wordpress #
#####################

# read -p "Would you like to install wordpress projects? " INSTALL_WP

# while said_yes $INSTALL_WP; do
#     echo -e "\n#########################"
#     echo "Installing Wordpress..."
#     echo -e "#########################\n"

#     read -p What is

#     ${WEBSERVER_DROPLET_ABSOLUTE_PATH}/wp-install.sh
#     read -p "Would you like to install another wordpress project? " INSTALL_WP

# done

# Performing final package updates
apt_quiet update && apt_quiet upgrade -y

echo -e "\n################################"
echo "Webserver provisioning complete!"
echo -e "################################\n"

# Print public keys
echo "Root public SSH key: "
cat "${HOME}/.ssh/id_ed.pub"
echo -e "\n${USERNAME} public SSH key: "
cat "${HOME_DIRECTORY}/.ssh/id_ed.pub"

echo -e "\n--------------------------------\n"
echo -e "\nAdd SSH to github."
echo -e "\nRun wp-install.sh for each wordpress project."

# Show help for wp-install
$DOTBASE/scripts/webserver/wp-install.sh -h

# Remove local dotfiles folder
LOCAL_DOTFILES=$HOME/.dotfiles
NEW_DOTFILES=$HOME_DIRECTORY/.dotfiles
if [ "$LOCAL_DOTFILES" != "$NEW_DOTFILES" ]; then
    rm -rf $HOME/.dotfiles
fi
# TODO Setup droplet to use DO Spaces
