#!/bin/bash

FILENAME=$(basename "$0" .sh)

# Check for USERNAME and set it if not found
[[ -z ${USERNAME:-} ]] && USERNAME=${SUDO_USER:-$USER}

# Check for HOME_DIRECTORY and set it if not found
[[ -z ${HOME_DIRECTORY:-} ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)

[[ -z ${DOTBASE:-} ]] && DOTBASE=$HOME_DIRECTORY/.dotfiles

if [ -f $DOTBASE/usertype.sh ]; then
    . $DOTBASE/usertype.sh
fi

# Source function utils
. $DOTBASE/functions/utils.sh

# Make sure script is run as root.
FILENAME=$(basename "$0" .sh)

usage_info() {
    BLNK=$(echo "$FILENAME" | sed 's/./ /g')
    echo "Usage: $FILENAME [{-f} force] [{-h} help]"
    echo -e "\n        e.g. $(magenta sudo ./$FILENAME -f)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-f} force        -- (Flag only) Force updating dotfiles. $(red OVERWRITES ANY LOCAL CHANGES)"
    echo "  {-h} help         -- Print this message"
    exit 0
}

while getopts 'hf' flag; do
    case "$flag" in
    h) help ;;
    f) FORCE="true" ;;
    *)
        usage_info
        exit 1
        ;;
    esac
done

cd $HOME_DIRECTORY/.dotfiles

if [ -z "$FORCE" ]; then
    git pull
else
    read -p "Are you sure you want to overwrite any local changes in ~/.dotfiles? [y/n] " REALLY_FORCE
    if said_yes $REALLY_FORCE; then
        git clean -i -d -f .
        git fetch
        git reset --hard HEAD
        git merge '@{u}'
    fi
fi

chmod -R +x $HOME_DIRECTORY/.dotfiles
