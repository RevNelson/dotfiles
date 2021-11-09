#!/bin/bash

SCRIPT_ABSOLUTE_PATH="$(dirname $(realpath $0))"

####################
# Script Variables #
####################

ENV_FILE="db-droplet.env"

if [[ ! -f ${ENV_FILE} ]]; then
    # Create .env file with required variables
    cat >${ENV_FILE} <<EOF
# Main user of droplet with privileges
USERNAME=

# SSH port to use. Will default to 22 if not specified
SSH_PORT=

# Private IP of this droplet
PRIVATE_IP=

# Private IP of the webserver droplet
WEBSERVER_IP=

# Password for MariaDB backup user
DB_BACKUP_USER_PASS=

# Password used for decrypting backups
ENCRYPTION_PASS=

EOF

    # Instruct user to fill in values for required variables
    echo "Edit ${ENV_FILE} to fill in necessary values, then run this script again."
    exit 1
fi

# Read env variables from file
set -o allexport
. $ENV_FILE
set +o allexport

# Check for all required arguments
[[ -z ${USERNAME} ]] && {
    echo "Must provide a username for the main user of this droplet with privileges."
    exit 1
}
[[ -z ${PRIVATE_IP} ]] && {
    echo "Must provide the private IP of this droplet."
    exit 1
}
[[ -z ${WEBSERVER_IP} ]] && {
    echo "Must provide the private IP of the webserver droplet."
    exit 1
}
[[ -z ${DB_BACKUP_USER_PASS} ]] && {
    echo "Must provide a password for the for MariaDB backup user."
    exit 1
}
[[ -z ${ENCRYPTION_PASS} ]] && {
    echo "Must provide a password used for decrypting backups."
    exit 1
}
[[ -z ${SSH_PORT} ]] && { export SSH_PORT=22; }

export HOME_DIRECTORY="/home/${USERNAME}"

##############################
# Initialize generic droplet #
##############################

. $SCRIPT_ABSOLUTE_PATH/../generic-droplet-provision.sh ${USERNAME} ${SSH_PORT}

# Add webserver to hosts file
echo "${WEBSERVER_IP} webserver" >>/etc/hosts

###################
# Install MariaDB #
###################

apt-get install wget software-properties-common -y
wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
chmod +x mariadb_repo_setup
./mariadb_repo_setup \
    --mariadb-server-version="mariadb-10.6"
apt update
apt install mariadb-server mariadb-backup -y
rm mariadb_repo_setup
ufw allow mysql

# Modify MariaDB server config to bind to private IP
sed -i "s/bind-address.*/bind-address = ${PRIVATE_IP}/g" /etc/mysql/mariadb.conf.d/50-server.cnf

# Modify MariaDB server config for SSL
SSL_CA_PATH="/etc/mysql/ssl/cacert.pem"
SSL_CERT_PATH="/etc/mysql/ssl/server-cert.pem"
SSL_KEY_PATH="/etc/mysql/ssl/server-key.pem"
CONFIG_PATH="/etc/mysql/mariadb.conf.d/50-server.cnf"

sed -i "s/#ssl-ca=.*/ssl-ca=${SSL_CA_PATH}/g" $CONFIG_PATH
sed -i "s/#ssl-cert=.*/ssl-cert=${SSL_CERT_PATH}/g" $CONFIG_PATH
sed -i "s/#ssl-key=.*/ssl-key=${SSL_KEY_PATH}/g" $CONFIG_PATH

#########################################
# Provision backup user with encryption #
#########################################

# Add user in mysql
mysql -e "GRANT SELECT, TRIGGER, EVENT, SHOW VIEW ON *.* TO 'mdbbackup'@'localhost' IDENTIFIED BY ${DB_BACKUP_USER_PASS}"
mysql -e "FLUSH PRIVILEGES"

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

. ./server-ssl.sh

############
# Clean up #
############

rm ENV_FILE

# TODO Add connections to dev server
# TODO Setup droplet to use DO Spaces
# TODO Add cron job for adding encrypted backups to Spaces
# TODO Import latest backup and restore databases
