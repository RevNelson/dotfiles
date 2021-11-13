#!/bin/bash

HOME=$HOME
OUTPUT_DIR="${HOME}/staging"
OUTPUT_FILE="${OUTPUT_DIR}/alldb_${date+\%Y-\%m-\%d}.sql.bz2.enc"

KEY_PATH="/etc/mysql/mdbbackup-pub.key"

# Dump all databases and directly zip and ecrypt the file.
mysqldump --routines --triggers --events --quick --single-transaction \
    --all-databases | bzip2 | openssl smime -encrypt -binary -text -aes256 \
    -out ${OUTPUT_FILE} -outform DER ${KEY_PATH} && chmod 600 ${OUTPUT_FILE}
