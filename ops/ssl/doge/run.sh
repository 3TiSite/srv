#!/usr/bin/env bash

DIR=$(dirname $(realpath "$0"))
cd $DIR
set -ex

pnpm i -C $DIR
set -o allexport
source $DIR/../../env.sh
source $CONF/doge.sh
set +o allexport

bunx cep -c src -o lib
./lib/main.js
