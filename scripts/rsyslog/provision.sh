#!/bin/bash

# Credit: https://techroads.org/docker-logging-to-the-local-os-that-works-with-compose-and-rsyslog/

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

HOME_DIRECTORY="/home/${USERNAME}"
DIRECTORY=$HOME_DIRECTORY/mariadb

TEMPLATE_PATH=/etc/rsyslog.d/40-docker.conf

LOG_DIRECTORY=/var/log/containers

LOGROTATE_PATH=/etc/logrotate.d/docker

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

# Create a template for the target log file
if [ ! -f "$TEMPLATE_PATH" ]; then
  echo "Creating a template for the target log file at $TEMPLATE_PATH ..."
  cat >${TEMPLATE_PATH} <<EOF
\$template CUSTOM_LOGS,"$LOG_DIRECTORY/%programname%.log"

if \$programname startswith  'docker-' then ?CUSTOM_LOGS
& ~
EOF
else
  echo "$TEMPLATE_PATH already exists."
fi

if [ ! -d "$LOG_DIRECTORY" ]; then
  echo "Creating $LOG_DIRECTORY and setting permissions..."
  mkdir -p $LOG_DIRECTORY
  chown -R syslog:adm $LOG_DIRECTORY
  chmod 775 $LOG_DIRECTORY
  echo "Restarting rsyslog..."
  systemctl restart rsyslog
else
  echo "$LOG_DIRECTORY already exists."
fi

if [ ! -f "${LOGROTATE_PATH}" ]; then
  echo "Creating logrotate settings at $LOGROTATE_PATH..."
  cat >${LOGROTATE_PATH} <<EOF
$LOG_DIRECTORY/*.log {
   daily
   rotate 20
   missingok
   compress
}
EOF
else
  echo "$LOGROTATE_PATH already exists."
fi
