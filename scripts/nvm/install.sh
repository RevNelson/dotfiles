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

#
##
###
##########
# Script #
##########
###
##
#

print_section 'Installing Docker...'

echo "Updating apt sources..."
apt_quiet update

NVM_VERSION="0.39.3"
export NVM_DIR=$HOME_DIRECTORY/.nvm
NVM_URL=https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh
echo "Installing NVM v$NVM_VERSION..."
mkdir -p $NVM_DIR
curl -s -o- $NVM_URL | NVM_DIR=$HOME_DIRECTORY/.nvm bash >/dev/null
chown -R $USERNAME:$USERNAME $NVM_DIR

echo "Installing required build dependencies..."
apt_quiet install build-essential

echo "Installing latest LTS node version..."
echo "$(magenta 'This may take a long time if it needs to be compiled.')"

sudo -E -H -u "$USERNAME" bash <<'EOF'
\. "$NVM_DIR/nvm.sh"
nvm install --lts >/dev/null
nvm use node
echo "Installing global node packages..."
npm install -g npm yarn uuid pm2 encoding >/dev/null
EOF
