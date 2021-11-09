#!/bin/bash

USER=$1
PORT=$2
DESTINATION_IP=$3
DESTINATION_PATH=$4

# Check for all required arguments
[[ -z ${USER} ]] && {
    echo "Must provide the username for the destination server as the first argument."
    exit 1
}
[[ -z ${PORT} ]] && {
    echo "No port provided as second argument. Defaulting to port 22."
    PORT=22
}
[[ -z ${private_ip} ]] && DESTINATION_IP="webserver"
[[ -z ${DESTINATION_PATH} ]] && DESTINATION_PATH="/tmp/certs"

SSL_CA_PATH="/etc/mysql/ssl/cacert.pem"
SSL_CERT_PATH="/etc/mysql/ssl/server-cert.pem"
SSL_KEY_PATH="/etc/mysql/ssl/server-key.pem"

TEMP_PATH=/tmp/certs

# Make a writeable temp directory
ssh ${USER}@${DESTINATION_IP} -p $PORT sudo mkdir -p $TEMP_PATH && sudo chmod 777 $TEMP_PATH

# Move files to TEMP_PATH
scp -P $PORT $SSL_CA_PATH $SSL_CERT_PATH $SSL_KEY_PATH ${USER}@${DESTINATION_IP}:${TEMP_PATH}

# Move certs to destination
ssh ${USER}@${DESTINATION_IP} -p $PORT sudo mkdir -p $DESTINATION_PATH &&
    sudo mv "${TEMP_PATH}/*.*" $DESTINATION_PATH

# Remove TEMP_PATH
ssh ${USER}@${DESTINATION_IP} -p $PORT sudo rm -rf $TEMP_PATH

# TODO - Add copy logic for dev server
