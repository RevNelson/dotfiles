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

# Check for USERNAME and set it if not found
[[ -z ${USERNAME:-} ]] && USERNAME=${SUDO_USER:-$USER}

TYPE="nextjs"

NGINX_PATH=/etc/nginx
SITES_A=$NGINX_PATH/sites-available
SITES_E=$NGINX_PATH/sites-enabled
PORT=3000
BRANCH="main"
FILES_DIR="files"

#
##
###
#############
# Functions #
#############
###
##
#

[[ -z ${DOTBASE:-} ]] && DOTBASE=$HOME/.dotfiles

# Source function utils
. $DOTBASE/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)
run_as_root $FILENAME

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-u} url] [{-r} repo] [{-d} directory] \\"
    echo "       $BLNK [{-w} wordpress] \\"
    echo -e "\n        e.g. $(magenta $FILENAME -u api.example.com -r https://github.com/user/repo.git -w)"
    echo -e "\n        e.g. $(magenta $FILENAME -u example.com -r https://github.com/user/repo.git -b dev -p 7555)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-u} url                 -- Set url for new site (Required)"
    echo "  {-r} repo                -- Repo address to clone"
    echo "  {-d} directory           -- Directory for repo to be cloned into (Default: ${FILES_DIR})"
    echo "  {-p} port                -- Port for nginx proxy pass (Default: ${PORT})"
    echo "  {-w} wordpress           -- (Flag only) New site is for wordpress instance. (Default type: ${TYPE})"
    echo "  {-h} help                -- (Flage only) View help docs for this script"
    exit 0
}

while getopts 'hu:r:b:d:p:w:' flag; do
    case "$flag" in
    h) help ;;
    u) URL="${OPTARG}" ;;
    r) REPO="${OPTARG}" ;;
    d) FILES_DIR="${OPTARG}" ;;
    d) PORT="${OPTARG}" ;;
    w) TYPE="wordpress" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

#
##
###
##########
# Script #
##########
###
##
#

# Check for all required arguments
[[ -z ${URL} ]] && {
    echo "No url provided."
    help
}

cd /sites
mkdir $URL
chown $USERNAME $URL

mkdir $URL/logs
chown www-data $URL/logs

if [ "${TYPE}" != "wordpress" ]; then
    cp $SITES_A/$TYPE.com $SITES_A/$URL
    sed -i "s/$TYPE.com/$URL/g" $SITES_A/$URL
    sed -i "s|$TYPE.com/files|$URL/$FILES_DIR|g" $SITES_A/$URL
    sed -i "s|http://localhost:3000|http://localhost:$PORT|g" $SITES_A/$URL

    ln -s $SITES_A/$URL $SITES_E/
else
    cp -r $SITES_A/wordpress.com $SITES_A/$URL
    mv $SITES_A/$URL/wordpress.com $SITES_A/$URL/$URL
    sed -i "s/wordpress.com/$URL/g" $SITES_A/$URL/$URL
    sed -i "s/wordpress.com/$URL/g" $SITES_A/$URL/location/fastcgi-cache.conf
    sed -i "s|wordpress.com/files|$URL/$FILES_DIR|g" $SITES_A/$URL/$URL

    ln -s $SITES_A/$URL/$URL $SITES_E/
fi

if [ ! -z "$REPO"]; then
    git clone $REPO /sites/$URL/$FILES_DIR
    git checkout $BRANCH
fi
