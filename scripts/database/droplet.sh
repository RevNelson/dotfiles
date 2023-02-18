#!/bin/bash

#
##
###
#############
# Variables #
#############
###
##
#

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
[[ -z ${SSH_PORT} ]] && export SSH_PORT=22

read -p "Private Webserver Server IP: " WEBSERVER_IP
[[ -z ${WEBSERVER_IP} ]] && {
    echo "Must provide the private IP of the webserver droplet."
    exit 1
}

read -p "Private Devserver IP (optional): " DEVSERVER_IP

export HOME_DIRECTORY="/home/${USERNAME}"

export USERTYPE="database-server"

#
##
###
#############
# Functions #
#############
###
##
#

##############################
# Initialize generic droplet #
##############################

. $DOTBASE/scripts/generic-droplet-provision.sh ${USERNAME} ${USER_PASSWORD} ${SSH_PORT}

print_section 'Performing database server specific provisioning...'

# Update dotbase for new user
DOTBASE=$HOME_DIRECTORY/.dotfiles

# Source function utils
. $DOTBASE/functions/utils.sh

# Make clients.sh
CLIENTS_PATH=$HOME_DIRECTORY/.config/clients.sh
cat >${CLIENTS_PATH} <<EOF
export WEBSERVER_IP=${WEBSERVER_IP}
EOF

# Add webserver to hosts file
echo "${WEBSERVER_IP} webserver" >>/etc/hosts

# Add devserver to hosts and clients files if given
[[ ! -z "$DEVSERVER_IP" ]] && {
    echo "${DEVSERVER_IP} devserver" >>/etc/hosts
    echo "export DEVSERVER_IP=${DEVSERVER_IP}" >>$CLIENTS_PATH
}

###################
# Install MariaDB #
###################

. $DOTBASE/scripts/database/mariadb-server.sh ${USERNAME} ${HOME_DIRECTORY} ${DOTBASE}

#############
# DO Spaces #
#############

. $DOTBASE/scripts/database/s3cmd-install.sh

echo "Performing final package updates..."
apt_quiet update && apt_quiet upgrade -y

su - $USERNAME

print_section 'Database server provisioning complete!'

# Print public keys
echo "Root public SSH key: "
cat "/root/.ssh/id_ed.pub"
echo -e "\n${USERNAME} public SSH key: "
cat "${HOME_DIRECTORY}/.ssh/id_ed.pub"

echo -e "\n--------------------------------\n"
echo -e "\nAdd SSH to github."
echo -e "\nRun ssl-copy.sh to place SSL certificates on clients."

# Show help for ssl-copy
$DOTBASE/scripts/database/ssl-copy.sh

# TODO Setup droplet to use DO Spaces
# TODO Add cron job for adding encrypted backups to Spaces
# TODO Import latest backup and restore databases
