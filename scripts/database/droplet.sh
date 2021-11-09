#!/bin/bash

DATABASE_SCRIPT_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
[[ -z ${SSH_PORT} ]] && export SSH_PORT=22

read -p "Private IP (this droplet): " PRIVATE_IP
[[ -z ${PRIVATE_IP} ]] && {
    echo "Must provide the private IP of this droplet."
    exit 1
}

read -p "Private Webserver Server IP: " WEBSERVER_IP
[[ -z ${WEBSERVER_IP} ]] && {
    echo "Must provide the private IP of the webserver droplet."
    exit 1
}

echo "Password for MariaDB backup user: "
read -s DB_BACKUP_USER_PASS
[[ -z ${DB_BACKUP_USER_PASS} ]] && {
    echo "Must provide a password for the MariaDB backup user."
    exit 1
}

echo "Password for decrypting database backups: "
read -s ENCRYPTION_PASS
[[ -z ${ENCRYPTION_PASS} ]] && {
    echo "Must provide a password for the database backup encryption."
    exit 1
}

export HOME_DIRECTORY="/home/${USERNAME}"

##############################
# Initialize generic droplet #
##############################

. $DATABASE_SCRIPT_ABSOLUTE_PATH/../generic-droplet-provision.sh ${USERNAME} ${USER_PASSWORD} ${SSH_PORT}

echo -e "\n###################################################"
echo "Performing database server specific provisioning..."
echo -e"###################################################\n"

DOTBASE=$HOME_DIRECTORY/.dotfiles

# Make usertype.sh
USERTYPE_PATH=$DOTBASE/usertype.sh
cat >${USERTYPE_PATH} <<EOF
export USERTYPE="database-server"
export SSH_PORT=${SSH_PORT}
EOF

# Add webserver to hosts file
echo "${WEBSERVER_IP} webserver" >>/etc/hosts

###################
# Install MariaDB #
###################

echo "Installing MariaDB Client..."
. $DOTBASE/scripts/database/mariadb-server.sh

#########################################
# Provision backup user with encryption #
#########################################

# Add backup user in mysql
mysql -e "GRANT SELECT, TRIGGER, EVENT, SHOW VIEW ON *.* TO 'mdbbackup'@'localhost' IDENTIFIED BY '${DB_BACKUP_USER_PASS}';"
mysql -e "FLUSH PRIVILEGES;"

# Create backup.cnf
cat >/etc/mysql/mariadb.conf.d/backup.cnf <<EOF
[mysqldump]
user = mdbbackup"
password = ${DB_BACKUP_USER_PASS}
EOF
chmod 600 /etc/mysql/mariadb.conf.d/backup.cnf

# Generate and sign encryption certificate
openssl genpkey -algorithm RSA -pass pass:$ENCRYPTION_PASS -out /etc/mysql/mdbbackup-priv.key -pkeyopt rsa_keygen_bits:4096 -aes256
openssl req -x509 -passin pass:$ENCRYPTION_PASS -nodes -key /etc/mysql/mdbbackup-priv.key -out /etc/mysql/mdbbackup-pub.key -subj "/C=US/ST=CA/L=LA/O=Dis/CN=MariaDB-backup"

##################################
# Generate SSL certs for MariaDB #
##################################

. $DOTBASE/scripts/database/server-ssl-generate.sh

# Performing final package updates
apt_quiet update && apt_quiet upgrade -y

su - $USERNAME

echo -e "\n######################################"
echo "Database server provisioning complete!"
echo -e "######################################\n"

# Print public keys
echo "Root public SSH key: "
cat "/root/.ssh/id_ed.pub"
echo -e "\n${USERNAME} public SSH key: "
cat "${HOME_DIRECTORY}/.ssh/id_ed.pub"

echo -e "\n--------------------------------\n"
echo -e "\nAdd SSH to github."
echo -e "\nRun ssl-copy.sh to place SSL certificates on clients."

# Show help for ssl-copy
$DOTBASE/scripts/database/ssl-copy.sh -h

# TODO Add connections to dev server
# TODO Setup droplet to use DO Spaces
# TODO Add cron job for adding encrypted backups to Spaces
# TODO Import latest backup and restore databases
