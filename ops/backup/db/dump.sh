#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
export MYSQL_PWD=$MYSQL_PWD
set -ex

mysqldump \
  --skip-set-charset \
  --events \
  --compress \
  --skip-add-drop-table \
  --set-gtid-purged=OFF \
  --column-statistics=0 \
  --routines \
  -u"$MYSQL_USER" \
  -P$MYSQL_PORT -h$MYSQL_HOST -d "$MYSQL_DB" >$MYSQL_DB.sql
# --column-statistics=0 \
# --compatible=no_table_options \

direnv exec . ./dump.coffee
