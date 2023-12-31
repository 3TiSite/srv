#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -ex

./gen.coffee
direnv exec . docker-compose up -d

p=""
while true; do
  docker-compose exec db true || (echo -e '\nERROR on start db\n' && docker-compose logs -n20 db && exit 1)
  echo "select 1;" | MYSQL_PWD=$DB_PASSWORD mysql -h 127.1 -P$DB_PORT -u $DB_USER $DB_NAME >/dev/null 2>&1 && break || true
  s=$(docker-compose logs db -n1)
  if [ "$p" != "$s" ]; then
    echo -e "\n$s"
    p=$s
  fi
  sleep 1
  echo -n ·
done

echo "\n"
docker-compose logs -n6
echo -e "\n"
docker-compose ps --format "{{.State}} | {{.Name}} | {{.Image}} | {{.Ports}}"
