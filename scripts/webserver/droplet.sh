#!/bin/bash

SCRIPT_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTING_PATH=$PWD

####################
# Script Variables #
####################

read -p "Username " USERNAME
read -p "SSH Port (Press Enter for 22) " SSH_PORT
read -p "Private Database Server IP " DATABASE_IP

# Check for all required arguments
[[ -z ${USERNAME} ]] && {
    echo "Must provide a username for the main user of this droplet with privileges."
    exit 1
}
[[ -z ${DATABASE_IP} ]] && {
    echo "Must provide the private IP of the database server droplet."
    exit 1
}
[[ -z ${SSH_PORT} ]] && export SSH_PORT=22

export HOME_DIRECTORY="/home/${USERNAME}"

##############################
# Initialize generic droplet #
##############################

. $SCRIPT_ABSOLUTE_PATH/../generic-droplet-provision.sh ${USERNAME} ${SSH_PORT}

echo -e "\n#############################################"
echo "Performing webserver specific provisioning..."
echo -e "#############################################\n"

# Make usertype.sh
USERTYPE_PATH=$HOME/.dotfiles/usertype.sh
cat >${USERTYPE_PATH} <<EOF
export USERTYPE="webserver"
EOF

# Add database server to hosts file
echo "${DATABASE_IP} database-server" >>/etc/hosts

###################
# Install MariaDB #
###################

echo "Installing MariaDB Client..."
apt_quiet install wget software-properties-common -y
wget -q https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
# TODO - Add check for successful download
chmod +x mariadb_repo_setup
./mariadb_repo_setup --mariadb-server-version="mariadb-10.6" >/dev/null 2>&1
apt_quiet update && apt_quiet install mariadb-client -y
rm mariadb_repo_setup

# Seed client config file for SSL
SSL_CA="ssl-ca=/etc/mysql/ssl/cacert.pem"
SSL_CERT="ssl-cert=/etc/mysql/ssl/client-cert.pem"
SSL_KEY="ssl-key=/etc/mysql/ssl/client-key.pem"
CONFIG_PATH="/etc/mysql/mariadb.conf.d/50-mysql-clients.cnf"

sed -i "/\[mysql\]/a ${SSL_KEY}" $CONFIG_PATH
sed -i "/\[mysql\]/a ${SSL_CERT}" $CONFIG_PATH
sed -i "/\[mysql\]/a ${SSL_CA}" $CONFIG_PATH

#################
# Install Nginx #
#################

echo "Installing Nginx..."
. $SCRIPT_ABSOLUTE_PATH/nginx-update.sh

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

#####################
# Install Wordpress #
#####################

read -p "Would you like to install wordpress projects? " INSTALL_WP

while said_yes $INSTALL_WP; do
    echo -e "\n#########################"
    echo "Installing Wordpress..."
    echo -e "#########################\n"

    read -p What is

    ${SCRIPT_ABSOLUTE_PATH}/wp-install.sh
    read -p "Would you like to install another wordpress project? " INSTALL_WP

done

# Performing final package updates
apt_quiet update && apt_quiet upgrade -y

echo -e "\n################################"
echo "Webserver provisioning complete!"
echo -e "################################\n"

# Print public key
echo "Root public SSH key: "
cat "/${STARTING_PATH}/.ssh/id_ed.pub"
echo -e "\n${USERNAME} public SSH key: "
cat "/home/${USERNAME}/.ssh/id_ed.pub"

echo -e "\n--------------------------------\n"
echo -e "\nAdd SSH to github."
echo -e "\nRun wp-install.sh for each wordpress project."
echo -e "\nRun certbot for each domain."
echo -e "sudo certbot --nginx -d example.com -d www.example.com\n"

# TODO Setup droplet to use DO Spaces
# TODO - Add NGINX blocks
