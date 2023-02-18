#!/bin/bash
set -euo pipefail

#
##
###
#############
# Variables #
#############
###
##
#

# Name of the user to create and grant sudo privileges
USERNAME=$1

[[ -z ${USERNAME} ]] && {
    echo "Must provide a username as the first argument."
    exit 1
}

USER_PASSWORD=$2
if [ -z ${USER_PASSWORD:-} ]; then
    echo "Please enter a password for user $USERNAME: "
    read -s $USER_PASSWORD
fi

# Port to set SSH to use. Will default to 22 if not given
SSH_PORT=$3

[[ -z ${SSH_PORT} ]] && { SSH_PORT=22; }

# Whether to copy over the root user's `authorized_keys` file to the new sudo
# user.
COPY_AUTHORIZED_KEYS_FROM_ROOT=true

# Additional public keys to add to the new sudo user
# OTHER_PUBLIC_KEYS_TO_ADD=(
#     "ssh-rsa AAAAB..."
#     "ssh-rsa AAAAB..."
# )
OTHER_PUBLIC_KEYS_TO_ADD=()

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

print_section 'Provisioning Droplet...'

HOME_DIRECTORY="/home/${USERNAME}"

echo "Performing initial package updates and installing zsh..."
apt_quiet update && apt_quiet upgrade
apt_quiet install zsh

echo "Checking SSH keys..."
# Generate SSH key for root user
HOST=$(cat /etc/hostname)
ROOT_SSH_KEY="/root/.ssh/id_ed"
if [ ! -f $ROOT_SSH_KEY ]; then
    ssh-keygen -t ed25519 -N "" -C "root@${HOST}" -f $ROOT_SSH_KEY >/dev/null
fi

########
# User #
########

# Add sudo user and grant privileges
if ! id -u "$USERNAME" >/dev/null; then
    echo "Creating new user: $USERNAME ..."
    useradd -m -p $USER_PASSWORD -s "/bin/zsh" --groups sudo $USERNAME

    # Create SSH directory for new user
    mkdir -p $HOME_DIRECTORY/.ssh

    echo "Generating SSH key for $USERNAME..."
    ssh-keygen -t ed25519 -N "" -C "${USERNAME}@${HOST}" -f "${HOME_DIRECTORY}/.ssh/id_ed" >/dev/null

    # Copy `authorized_keys` file from root if requested
    if [ "${COPY_AUTHORIZED_KEYS_FROM_ROOT}" = true ]; then
        cp /root/.ssh/authorized_keys $HOME_DIRECTORY/.ssh
    fi

    # Add additional provided public keys
    for PUB_KEY in "${OTHER_PUBLIC_KEYS_TO_ADD[@]}"; do
        echo "${PUB_KEY}" >>"${HOME_DIRECTORY}/.ssh/authorized_keys"
    done

    # Add config file for github
    SSH_CONFIG_PATH="${HOME_DIRECTORY}/.ssh/config"
    cat >${SSH_CONFIG_PATH} <<EOF
Host github.com
    Hostname        github.com
    IdentityFile    ~/.ssh/id_ed
    IdentitiesOnly yes
EOF

    # Adjust SSH configuration ownership and permissions
    chmod 0700 "${HOME_DIRECTORY}/.ssh"
    chmod 0600 "${HOME_DIRECTORY}/.ssh/authorized_keys"
    chown -R "${USERNAME}:${USERNAME}" "${HOME_DIRECTORY}/.ssh"

    # Add exception for SSH and then enable UFW firewall
    ufw allow ${SSH_PORT}/tcp >/dev/null
    ufw --force enable >/dev/null

    echo "SSH configured."
else
    echo "User $USERNAME already exists. Moving on..."
fi

# Check whether the root account has a real password set
ENCRYPTED_ROOT_PW="$(grep root /etc/shadow | cut --delimiter=: --fields=2)"

if [ "${ENCRYPTED_ROOT_PW}" != "*" ]; then
    # Transfer auto-generated root password to user if present
    # and lock the root account to password-based access
    echo "${USERNAME}:${ENCRYPTED_ROOT_PW}" | chpasswd --encrypted
    passwd --lock root
else
    # Delete invalid password for user if using keys so that a new password
    # can be set without providing a previous value
    passwd --delete $USERNAME >/dev/null
fi

#######
# SSH #
#######

# Change SSH port
sed -i "/^#Port/a Port ${SSH_PORT}" /etc/ssh/sshd_config
service ssh restart

echo "$(magenta SSH has been set to use port) $(blue ${SSH_PORT})"

###########
# Dotbase #
###########

echo "Copying dotfiles to $USERNAME's home folder..."

# Copy .dotfiles to new user folder, apply ownership, and make executable
cp -r /root/.dotfiles/ ${HOME_DIRECTORY}
DOTBASE=$HOME_DIRECTORY/.dotfiles
chown -R $USERNAME:$USERNAME $DOTBASE
chmod -R +x $DOTBASE

# Prepare dotfiles for new user
echo "Installing dotbase for $USERNAME..."
export HOME_DIRECTORY=$HOME_DIRECTORY
sudo -E -u "$USERNAME" sh <<'EOF'
bash $HOME_DIRECTORY/.dotfiles/install >/dev/null;
zsh;
echo 'Sourcing .zshrc ...';
source $HOME_DIRECTORY/.zshrc >/dev/null 2>&1;
EOF

[[ -z ${USERTYPE:-} ]] && read -p "What type of server is this (webserver, devserver, database-server)? " USERTYPE
# Make usertype.sh
USERTYPE_PATH=$HOME_DIRECTORY/.config/usertype.sh
cat >${USERTYPE_PATH} <<EOF
export USERTYPE=${USERTYPE}
EOF

# Make ssh-port.sh
SSH_PORT_PATH=$HOME_DIRECTORY/.config/ssh-port.sh
cat >${SSH_PORT_PATH} <<EOF
export SSH_PORT=${SSH_PORT}
EOF
