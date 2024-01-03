#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
export MYSQL_PWD=$DB_PASSWORD
set -ex

mysqldump \
  --skip-set-charset \
  --events \
  --skip-add-drop-table \
  --set-gtid-purged=OFF \
  --column-statistics=0 \
  --routines \
  -u"$DB_USER" \
  -P$DB_PORT -h$DB_HOST -d "$DB_NAME" >$DB_NAME.sql
# --column-statistics=0 \
# --compatible=no_table_options \

direnv exec . ./dump.coffee
