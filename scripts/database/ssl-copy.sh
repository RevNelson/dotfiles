#!/bin/bash

FILENAME=$(basename "$0" .sh)

# Check for USERNAME and set it if not found
[[ -z "$USERNAME" ]] && USERNAME=${SUDO_USER:-$USER}

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-u} server-user] [{-p} server-port] \\"
    echo "       $BLNK [{-i} server-ip] [{-d} destination-directory] \\"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME -u ${USERNAME} -p 22 -i 192.168.0.30 -d /home/${USERNAME}/certs)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

error() {
    echo -e "$FILENAME: $*" >&2
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-u} server-user         -- Set user for connecting to server (default: ${USERNAME}"
    echo "  {-p} server-port         -- Set port for SSH connection (default: ${SSH_SERVER_PORT})"
    echo "  {-i} server-ip           -- Set server ip for where to copy certificates (default: webserver)"
    echo "  {-d} destination-dir     -- Set user for chmod on public folder (default: /tmp/certs)"
    exit 0
}

while getopts 'hu:p:i:d:' flag; do
    case "${flag}" in
    h)
        help
        exit 1
        ;;
    u) SERVER_USER="${OPTARG}" ;;
    p) SERVER_PORT="${OPTARG}" ;;
    i) DESTINATION_IP="${OPTARG}" ;;
    d) DESTINATION_PATH="${OPTARG}" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

# Check for all required arguments
[[ -z ${SERVER_USER} ]] && {
    echo "No port provided. Defaulting to port $USERNAME."
    SERVER_USER=$USERNAME
}
[[ -z ${SERVER_PORT} ]] && {
    echo "No port provided. Defaulting to port $SSH_PORT."
    SERVER_PORT=$SSH_PORT
}
[[ -z ${DESTINATION_IP} ]] && {
    echo "Must provide the destination for the copy. e.g. webserver , devserver , 192.168.0.30"
    help
}
[[ -z ${DESTINATION_PATH} ]] && DESTINATION_PATH="/tmp/certs"

SSL_CA_PATH="/etc/mysql/ssl/cacert.pem"
SSL_CERT_PATH="/etc/mysql/ssl/server-cert.pem"
SSL_KEY_PATH="/etc/mysql/ssl/server-key.pem"

TEMP_PATH=/tmp/certs

# Make a writeable temp directory
ssh ${SERVER_USER}@${DESTINATION_IP} -p $SERVER_PORT sudo mkdir -p $TEMP_PATH && sudo chmod 777 $TEMP_PATH

# Move files to TEMP_PATH
scp -P $SERVER_PORT $SSL_CA_PATH $SSL_CERT_PATH $SSL_KEY_PATH ${SERVER_USER}@${DESTINATION_IP}:${TEMP_PATH}

# Move certs to destination
ssh ${SERVER_USER}@${DESTINATION_IP} -p $SERVER_PORT sudo mkdir -p $DESTINATION_PATH &&
    sudo mv "${TEMP_PATH}/*.*" $DESTINATION_PATH

# Remove TEMP_PATH
ssh ${SERVER_USER}@${DESTINATION_IP} -p $SERVER_PORT sudo rm -rf $TEMP_PATH
