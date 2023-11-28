#!/usr/bin/env bash

DIR=$(dirname $(realpath "$0"))
cd $DIR
set -ex

./_/run.sh
./ali/setup.sh
./doge/setup.sh
