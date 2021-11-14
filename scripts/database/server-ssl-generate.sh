#!/bin/bash

SSL_GENERATE_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for HOME_DIRECTORY and set it if not found
[[ -z ${HOME_DIRECTORY:-} ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)

#############
# Functions #
#############

# Source function utils
. $HOME_DIRECTORY/.dotfiles/functions/utils.sh

while getopts 'f' flag; do
    case "${flag}" in
    f)
        CONFIRMED="y"
        ;;
    esac
done

[[ -z ${CONFIRMED:-} ]] && {
    echo -e "\nAre you sure you want to continue? All connections will be broken until you run $(magenta ssl-copy -i CLIENT_SERVER)."
    echo "You can skip this check by providing the '-f' flag. i.e. ssl-update -f"
    read -p "Please type 'yes' to confirm: " CONFIRMED
    echo ""
}

if ! said_yes $CONFIRMED; then
    echo -e "SSL generation cancelled. No changes will be made.\n"
    exit 1
fi

mkdir -p $HOME_DIRECTORY/certs && cd $HOME_DIRECTORY/certs

openssl genrsa 4096 >ca-key.pem
openssl req -new -x509 -nodes -days 3650 -key ca-key.pem -out cacert.pem -subj "/C=US/ST=CA/L=LA/O=Dis/CN=MariaDB-admin"
openssl req -newkey rsa:4096 -days 3650 -nodes -keyout server-key.pem -out server-req.pem -subj "/C=US/ST=CA/L=LA/O=Dis/CN=MariaDB-server"
openssl rsa -in server-key.pem -out server-key.pem
openssl x509 -req -in server-req.pem -days 3650 -CA cacert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

CERTS_DESTINATION=/etc/mysql/ssl
mkdir -p $CERTS_DESTINATION
mv *.* $CERTS_DESTINATION && cd $CERTS_DESTINATION
openssl req -newkey rsa:2048 -days 3650 -nodes -keyout client-key.pem -out client-req.pem -subj "/C=US/ST=CA/L=LA/O=Dis/CN=MariaDB-client"
openssl rsa -in client-key.pem -out client-key.pem
openssl x509 -req -in client-req.pem -days 3650 -CA cacert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem

# Set certs folder to mysql ownership
chown -R mysql:mysql $CERTS_DESTINATION

# Restart mysql to apply new certificates
systemctl restart mysql

echo -e "\n$(green Certificates are installed. Run ssl-copy.sh to place SSL certificates on clients.)\n"

$SSL_GENERATE_ABSOLUTE_PATH/ssl-copy.sh -h
