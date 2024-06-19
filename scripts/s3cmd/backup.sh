#!/bin/sh

# Add your backup dir location, s3 location, password, mysql location and mysqldump location
DATE=$(date +%d-%m-%Y)

GZIP=$(which gzip)
MYSQL=$(which mysql)
MYSQLDUMP=$(which mysqldump)
HOST=$DB_CONTAINER_NAME

# get a list of databases
databases=$($MYSQL -h ${HOST} -u root -p$DB_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema)")

## Add host to mysqldump with docker container name

# dump each database in separate name
for db in $databases; do
  echo $db
  $MYSQLDUMP --force --opt -h ${HOST} -u root -p$DB_PASSWORD --skip-lock-tables --databases $db | gzip | s3cmd \
    --access_key ${S3_ACCESS_KEY} --access_secret ${S3_ACCESS_SECRET} --gpg_passphrase ${S3_ENCRYPTION_PASSWORD} \
    put - s3://$S3_BUCKET_NAME/$S3_DIRECTORY_NAME/$db/$db-$DATE.sql.gz

  # TODO: Add checks to make sure backup was sent successfully
done
