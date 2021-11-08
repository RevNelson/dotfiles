#! /usr/bin/env bash

#
#
# Modified from WP-Salts-Update-CLI
#
# https://github.com/ahmadawais/WP-Salts-Update-CLI
#
#

[[ -z HOME_DIRECTORY ]] && HOME_DIRECTORY=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)

cd $HOME_DIRECTORY

# Start the loop.
find . -name wp-config.php -print | while read line; do

    # Get dir path where wp-config.php file is found.
    DIR=$(cd -P "$(dirname "$line")" && pwd)/

    cd $DIR

    ## Download the new salts to file cal salts.
    curl "https://api.wordpress.org/secret-key/1.1/salt/" -sSo salts

    # Split wp-config.php into 3 on the first and last definition statements.
    csplit -s wp-config.php '/AUTH_KEY/' '/NONCE_SALT/+1'

    # Recombine the first part, the new salts and the last part.
    cat xx00 salts xx02 >wp-config.php

    # Tidy up.
    rm salts xx00 xx01 xx02

    echo -e "\nSalts updated at: $line"
    cd $HOME_DIRECTORY
done

echo ""
