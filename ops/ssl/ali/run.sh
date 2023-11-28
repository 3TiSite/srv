#!/usr/bin/env bash

DIR=$(dirname $(realpath "$0"))
cd $DIR
set -ex

pnpm_i $DIR
$(dirname $DIR)/init.sh

bunx cep -c src -o lib

./lib/main.js
