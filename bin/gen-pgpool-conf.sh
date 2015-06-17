#!/usr/bin/env bash

POSTGRES_URLS=${PGBOUNCER_URLS:-DATABASE_URL}

for POSTGRES_URL in $POSTGRES_URLS
do
  eval POSTGRES_URL_VALUE=\$$POSTGRES_URL
  DB=$(echo $POSTGRES_URL_VALUE | perl -lne 'print "$1 $2 $3 $4 $5 $6 $7" if /^postgres:\/\/([^:]+):([^@]+)@(.*?):(.*?)\/(.*?)(\\?.*)?$/')
  DB_URI=( $DB )
  DB_USER=${DB_URI[0]}
  DB_PASS=${DB_URI[1]}
  DB_HOST=${DB_URI[2]}
  DB_PORT=${DB_URI[3]}
  DB_NAME=${DB_URI[4]}
  DB_MD5_PASS="md5"`echo -n ${DB_PASS}${DB_USER} | md5sum | awk '{print $1}'`

  cat >> /app/vendor/pgpool/pgpool.conf << EOFEOF
backend_hostname0 = '$DB_HOST'
backend_port0 = $DB_PORT
backend_weight0 = 1
backend_data_directory0 = '/data'
backend_flag0 = 'ALLOW_TO_FAILOVER'
health_check_user = '$DB_USER'
health_check_password = '$DB_PASS'
EOFEOF

done

