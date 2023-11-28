#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
export MYSQL_PWD=$DB_PASSWORD
set -ex

mysqldump \
  --skip-set-charset \
  --events \
  --skip-add-drop-table \
  --routines \
  --compatible=no_table_options \
  -u"$DB_USER" \
  -P$DB_PORT -h$DB_HOST -d "$DB_DB" >$DB_DB.sql
# --column-statistics=0 \
./dump.coffee
