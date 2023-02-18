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

read -p "Private IP (this droplet): " PRIVATE_IP
[[ -z ${PRIVATE_IP} ]] && {
    echo "Must provide the private IP of this droplet."
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

# Check for USERNAME and set it if not found
[[ -z ${USERNAME:-} ]] && USERNAME=${SUDO_USER:-$USER}

# Check for HOME_DIRECTORY and set it if not found
[[ -z ${HOME_DIRECTORY:-} ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
[[ -z ${DOTBASE:-} ]] && DOTBASE=$HOME_DIRECTORY/.dotfiles

# Set MariaDB bind address if given
if [ $# -lt 1 ]; then
    [[ -z ${PRIVATE_IP:-} ]] && PRIVATE_IP="0.0.0.0"
else
    PRIVATE_IP=$1
fi

#
##
###
#############
# Functions #
#############
###
##
#

# Source function utils
. $DOTBASE/functions/utils.sh

#
##
###
##########
# Script #
##########
###
##
#

echo "Installing MariaDB Client..."

apt_quiet install wget software-properties-common -y

if ! cmd_exists mysql; then
    wget -q https://downloads.mariadb.com/MariaDB/mariadb_repo_setup

    if [ -f mariadb_repo_setup ]; then
        chmod +x mariadb_repo_setup
        ./mariadb_repo_setup --mariadb-server-version="mariadb-10.11" >/dev/null 2>&1
        apt_quiet update && apt_quiet install mariadb-server mariadb-backup -y
        rm mariadb_repo_setup
    else
        echo "Error downloading MariaDB repo setup file. Please run mariadb-setup again."
    fi

    ufw allow mysql

fi

# Run mysql_secure_installation
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<EOF | mysql_secure_installation
      # current root password (emtpy after installation)
    n # Set root password?
    y # Remove anonymous users?
    y # Disallow root login remotely?
    y # Remove test database and access to it?
    y # Reload privilege tables now?
EOF

echo "Adding server config file for SSL..."
SSL_CONF_FILE="$DOTBASE/scripts/database/mariadb-server.cnf"
SSL_CONF_DESTINATION="/etc/mysql/mariadb.conf.d/99-server-ssl.cnf"

if [ -f $SSL_CONF_FILE ]; then
    cp $SSL_CONF_FILE $SSL_CONF_DESTINATION
fi

# Check that file has been placed
if [ -f $SSL_CONF_DESTINATION ]; then
    sed -i "s/bind-address.*/bind-address = ${PRIVATE_IP}/g" $SSL_CONF_DESTINATION
    echo "MariaDB SSL config placed at $SSL_CONF_DESTINATION"
fi

#########################################
# Provision backup user with encryption #
#########################################

echo "Adding user and encryption for backups..."
# Add backup user in mysql
mysql -e "GRANT SELECT, TRIGGER, EVENT, SHOW VIEW ON *.* TO 'mdbbackup'@'localhost' IDENTIFIED BY '${DB_BACKUP_USER_PASS}';"
mysql -e "FLUSH PRIVILEGES;"

# Create backup.cnf
cat >/etc/mysql/mariadb.conf.d/backup.cnf <<EOF
[mysqldump]
user = mdbbackup
password = ${DB_BACKUP_USER_PASS}
EOF
chmod 600 /etc/mysql/mariadb.conf.d/backup.cnf

DB_BACKUP_KEY="$HOME_DIRECTORY/backup.key"
if [ ! -f $DB_BACKUP_KEY ]; then
    echo "Do you want to generate a new encryption key for backups?"
    read -p "If not, you will need to run $(green mysql-backup-key) after provisioning. [y/n] " NEW_BACKUP_KEY
    if said_yes $NEW_BACKUP_KEY; then
        # Generate and sign encryption certificate
        openssl genpkey -algorithm RSA -pass pass:$ENCRYPTION_PASS -out $HOME_DIRECTORY/backup.key -pkeyopt rsa_keygen_bits:4096 -aes256
        . $DOTBASE/scripts/database/mysql-set-backup-key.sh -k $DB_BACKUP_KEY
    fi
else
    . $DOTBASE/scripts/database/mysql-set-backup-key.sh -k $DB_BACKUP_KEY
fi

##################################
# Generate SSL certs for MariaDB #
##################################

. $DOTBASE/scripts/database/server-ssl-generate.sh -f

echo "MariaDB has been installed and configured."
