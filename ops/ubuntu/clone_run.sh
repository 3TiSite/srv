#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -ex

apt install -y git curl wget
mkdir -p ~/3Ti
cd ~/3Ti
git clone --depth=1 https://atomgit.com/3ti/srv.git
cd srv/ops/ubuntu
./init.sh
