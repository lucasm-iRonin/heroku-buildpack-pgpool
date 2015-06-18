#!/usr/bin/env bash

mkdir -p /app/vendor/pgpool
mkdir -p /app/vendor/postgresql

wget https://raw.githubusercontent.com/devopscenter/heroku-buildpack-pgpool/master/etc/pgpool.conf -O /app/vendor/pgpool/pgpool.conf

wget https://github.com/devopscenter/heroku-buildpack-pgpool/raw/master/bin/pgpool-3.4.2 -O /app/vendor/pgpool/pgpool

chmod 755 /app/vendor/pgpool/pgpool

wget https://raw.githubusercontent.com/devopscenter/docker-stack/master/web/python-apache-pgpool/pgpool/pool_hba.conf -O /app/vendor/pgpool/pool_hba.conf

POSTGRES_URLS=${PGBOUNCER_URLS:-DATABASE_URL}

i=0

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
backend_hostname$i = '$DB_HOST'
backend_port$i = $DB_PORT
backend_weight$i = 1
backend_data_directory$i = '/data'
backend_flag$i = 'ALLOW_TO_FAILOVER'
health_check_user = '$DB_USER'
health_check_password = '$DB_PASS'
health_check_period = 0
sr_check_user = '$DB_USER'
sr_check_password = '$DB_PASS'
sr_check_period = 0
EOFEOF

  i=$(($i+1))
done

