#!/bin/bash

SSL_GENERATE_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for HOME_DIRECTORY and set it if not found
[[ -z "$HOME_DIRECTORY" ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)

#############
# Functions #
#############

# Load utils (error, okay, run_as_root)
. $HOME_DIRECTORY/.dotfiles/functions/utils.sh

mkdir $HOME_DIRECTORY/certs && cd $HOME_DIRECTORY/certs

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

# Restart mysql to apply new certificates
systemctl restart mysql

echo "Certificates are installed. Run ssl-copy.sh to place SSL certificates on clients."

$SSL_GENERATE_ABSOLUTE_PATH/ssl-copy.sh -h
