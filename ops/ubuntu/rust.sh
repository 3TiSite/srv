#!/usr/bin/env bash

set -ex

dir=$(dirname $(realpath ${BASH_SOURCE[0]}))

source $dir/gfw.sh

etc_profile=/etc/profile.d
etc_profile_rust=$etc_profile/rust.sh

docker=$dir/../../docker/dev

rust_proxy=$etc_profile/rust.proxy.sh

[ $GFW ] &&
  cp -f $docker/zh/os$rust_proxy $rust_proxy &&
  source $rust_proxy

if [ ! -f "~/.cargo/config" ]; then
  [ $GFW ] &&
    mkdir -p ~/.cargo &&
    cp -f $docker/zh/os/root/.cargo/config ~/.cargo/
fi

cp -f $docker/_$etc_profile_rust $etc_profile_rust

source $etc_profile_rust

if [ ! -f "$CARGO_HOME/env" ]; then
  mkdir -p $CARGO_HOME
  $CURL https://sh.rustup.rs -sSf |
    sh -s -- -y --no-modify-path --default-toolchain nightly
fi

source $CARGO_HOME/env
