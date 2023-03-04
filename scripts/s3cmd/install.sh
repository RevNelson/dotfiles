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

CONFIG_PATH=/root/.s3cfg

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
    echo "Usage: $FILENAME [{-k} access key] [{-s} access secret] [{-e} encryption password] \\"
    echo -e "\n        e.g. $(magenta $FILENAME -k EI3pifw5i2334 -s eifgn3gNE -e eeinsr54p3kmz)"

}

usage() {
    exec 1>2 # Send standard output to standard error
    usage_info
    exit 1
}

help() {
    usage_info
    echo
    echo "  {-k} access key"
    echo "  {-s} access secret"
    echo "  {-e} encryption password"
    echo "  {-c} config path (Default is: $CONFIG_PATH)"
    echo "  {-h} help"
    exit 0
}

####################
# Script Variables #
####################

while getopts 'hk:s:e:c:' flag; do
    case $flag in
    h)
        usage_info
        exit 1
        ;;
    k) ACCESS_KEY="${OPTARG}" ;;
    s) ACCESS_SECRET="${OPTARG}" ;;
    e) ENCRYPTION_PASSWORD="${OPTARG}" ;;
    c) CONFIG_PATH="${OPTARG}" ;;
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

print_section "Installing s3cmd..."

echo "Updating apt sources..."
apt_quiet update

echo "Installing dependencies..."
apt_quiet install python3-pip

echo "Installing s3cmd"
pip install s3cmd -U >/dev/null 2>&1

echo "Creating s3cmd config..."

cat >${CONFIG_PATH} <<EOF
[default]
access_key = $ACCESS_KEY
access_token =
add_encoding_exts =
add_headers =
bucket_location = US
ca_certs_file =
cache_file =
check_ssl_certificate = True
check_ssl_hostname = True
cloudfront_host = cloudfront.amazonaws.com
connection_max_age = 5
connection_pooling = True
content_disposition =
content_type =
default_mime_type = binary/octet-stream
delay_updates = False
delete_after = False
delete_after_fetch = False
delete_removed = False
dry_run = False
enable_multipart = True
encoding = UTF-8
encrypt = False
expiry_date =
expiry_days =
expiry_prefix =
follow_symlinks = False
force = False
get_continue = False
gpg_command = /usr/bin/gpg
gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_passphrase = $ENCRYPTION_PASSWORD
guess_mime_type = True
host_base = s3.amazonaws.com
host_bucket = %(bucket)s.s3.amazonaws.com
human_readable_sizes = False
invalidate_default_index_on_cf = False
invalidate_default_index_root_on_cf = True
invalidate_on_cf = False
kms_key =
limit = -1
limitrate = 0
list_allow_unordered = False
list_md5 = False
log_target_prefix =
long_listing = False
max_delete = -1
mime_type =
multipart_chunk_size_mb = 15
multipart_copy_chunk_size_mb = 1024
multipart_max_chunks = 10000
preserve_attrs = True
progress_meter = True
proxy_host =
proxy_port = 0
public_url_use_https = False
put_continue = False
recursive = False
recv_chunk = 65536
reduced_redundancy = False
requester_pays = False
restore_days = 1
restore_priority = Standard
secret_key = $ACCESS_SECRET
send_chunk = 65536
server_side_encryption = False
signature_v2 = False
signurl_use_https = False
simpledb_host = sdb.amazonaws.com
skip_existing = False
socket_timeout = 300
ssl_client_cert_file =
ssl_client_key_file =
stats = False
stop_on_error = False
storage_class =
throttle_max = 100
upload_id =
urlencoding_mode = normal
use_http_expect = False
use_https = True
use_mime_magic = True
verbosity = WARNING
website_endpoint = http://%(bucket)s.s3-website-%(location)s.amazonaws.com/
website_error =
website_index = index.html
EOF

echo "$(green s3cmd is now installed.)"
