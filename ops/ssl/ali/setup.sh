#!/usr/bin/env bash

DIR=$(dirname $(realpath "$0"))
cd $DIR
set -ex

./run.sh

cron_add '30 3 */10' $DIR lib/main.js
