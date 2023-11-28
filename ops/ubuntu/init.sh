#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -ex

./chrony.sh
. ./rust.sh
./cargo_install/must.sh
./zram.sh
./docker.sh
