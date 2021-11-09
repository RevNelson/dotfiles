#!/bin/bash
set -euo pipefail

########################
### SCRIPT VARIABLES ###
########################

# Name of the user to create and grant sudo privileges
USERNAME=$1

[[ -z ${USERNAME} ]] && {
    echo "Must provide a username as the first argument."
    exit 1
}

USER_PASSWORD=$2
[[ -z ${USER_PASSWORD} ]] && { SSH_PORT=22; }

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

####################
### SCRIPT LOGIC ###
####################
echo -e "\n#######################"
echo "Provisioning Droplet..."
echo -e "#######################\n"

HOME_DIRECTORY="/home/${USERNAME}"

echo "Performing initial package updates and installing zsh..."
apt-get update >/dev/null && apt-get upgrade -y >/dev/null
apt-get install zsh -y >/dev/null

# Add sudo user and grant privileges
useradd -m -p $USER_PASSWORD -s "/bin/zsh" --groups sudo $USERNAME

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

# Create SSH directory for sudo user
mkdir -p $HOME_DIRECTORY/.ssh

# Generate SSH key for root and new user
HOST=$(cat /etc/hostname)
ssh-keygen -t ed25519 -N "" -C "root@${HOST}" -f "/root/.ssh/id_ed" >/dev/null
ssh-keygen -t ed25519 -N "" -C "${USERNAME}@${HOST}" -f "${HOME_DIRECTORY}/.ssh/id_ed" >/dev/null

# Copy `authorized_keys` file from root if requested
if [ "${COPY_AUTHORIZED_KEYS_FROM_ROOT}" = true ]; then
    cp /root/.ssh/authorized_keys $HOME_DIRECTORY/.ssh
fi

# Add additional provided public keys
for PUB_KEY in "${OTHER_PUBLIC_KEYS_TO_ADD[@]}"; do
    echo "${PUB_KEY}" >>"${HOME_DIRECTORY}/.ssh/authorized_keys"
done

# Adjust SSH configuration ownership and permissions
chmod 0700 "${HOME_DIRECTORY}/.ssh"
chmod 0600 "${HOME_DIRECTORY}/.ssh/authorized_keys"
chown -R "${USERNAME}:${USERNAME}" "${HOME_DIRECTORY}/.ssh"

# Change SSH port
sed -i "/^#Port/a Port ${SSH_PORT}" /etc/ssh/sshd_config
service ssh restart

# Add exception for SSH and then enable UFW firewall
ufw allow ${SSH_PORT}/tcp >/dev/null
ufw --force enable >/dev/null

echo "SSH has been set to use port ${SSH_PORT}"

###########
# Dotbase #
###########

echo "Installing dotbase for $USERNAME"

# Copy .dotfiles to new user folder, apply ownership, and make executable
cp -r /root/.dotfiles/ ${HOME_DIRECTORY}
chown -R $USERNAME:$USERNAME $HOME_DIRECTORY/.dotfiles
chmod +x $HOME_DIRECTORY/.dotfiles

# Prepare dotfiles for new user
sudo -i -u $USERNAME bash <<EOF
. ~/.dotbase/install
zsh source ~/.zshrc
EOF

echo "Forcing git to use SSH connections for Github..."
# Force git to use SSH on github
git config --global url."git@github.com:".insteadOf "https://github.com/"
