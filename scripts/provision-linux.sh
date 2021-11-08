read -p "Provision Droplet? " PROVISION_DROPLET

# Source function utils
. $DOTBASE/functions/utils.sh

while said_yes $PROVISION_DROPLET; do
    read -p "Droplet type (webserver, database, devserver): " DROPLET_TYPE
    if [ "$DROPLET_TYPE" = "webserver" ]; then
        . $DOTBASE/scripts/webserver/droplet.sh
    elif [ "$DROPLET_TYPE" = "database" ]; then
        echo "Provision Database Droplet!"
    elif [ "$DROPLET_TYPE" = "devserver" ]; then
        echo "Provision Devserver Droplet!"
    else
        ERR="true"
        echo "Input not recognized. Available options are: "
        echo "$(magenta 'webserver', 'database', or 'devserver')"
    fi
    [[ -z "$ERR" ]] && PROVISION_DROPLET="no"
done

# TODO - Add provisioning for standard ubuntu VM (not droplet)
