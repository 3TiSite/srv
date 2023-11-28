#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -ex

lang_sh=../../../docker/dev/zh/os/etc/profile.d/lang.sh
source $lang_sh
apt-get install -y language-pack-zh-hans
cp -f $lang_sh /etc/profile.d
locale-gen zh_CN.UTF-8
