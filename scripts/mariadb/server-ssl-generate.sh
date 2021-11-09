#!/bin/bash

SCRIPT_ABSOLUTE_PATH="$(dirname $(realpath $0))"

mkdir ~/certs && cd ~/certs

openssl genrsa 4096 >ca-key.pem
openssl req -new -x509 -nodes -days 3650 -key ca-key.pem -out cacert.pem -subj "/C=US/ST=CA/L=LA/O=Dis/CN=MariaDB-admin"
openssl req -newkey rsa:4096 -days 3650 -nodes -keyout server-key.pem -out server-req.pem -subj "/C=US/ST=CA/L=LA/O=Dis/CN=MariaDB-server"
openssl rsa -in server-key.pem -out server-key.pem
openssl x509 -req -in server-req.pem -days 3650 -CA cacert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

mkdir -p /etc/mysql/ssl
mv *.* /etc/mysql/ssl && cd /etc/mysql/ssl
openssl req -newkey rsa:2048 -days 3650 -nodes -keyout client-key.pem -out client-req.pem -subj "/C=US/ST=CA/L=LA/O=Dis/CN=MariaDB-client"
openssl rsa -in client-key.pem -out client-key.pem
openssl x509 -req -in client-req.pem -days 3650 -CA cacert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem

systemctl restart mysql

echo "Certificates are installed. Copying the certificates to the webserver."

. $SCRIPT_ABSOLUTE_PATH/ssl-copy.sh
