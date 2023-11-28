#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -ex

../ops/backup/db/load.coffee

APT_URL=api/.url

ensure() {
  for pkg in "$@"; do
    if ! command -v $pkg &>/dev/null; then
      cargo install $pkg
    fi
  done
}

ensure cargo-expand

if [ ! -f "url.nt" ]; then
  if [ -f "../../conf/srv/rust/url.nt" ]; then
    ln -s ../../conf/srv/rust/url.nt .
  else
    cp example.url.nt url.nt
  fi
fi

run() {
  for i in $@; do
    direnv exec . ./sh/$i
  done
}
run gen.coffee
cargo fmt

api_dir=$(realpath $DIR/../../api-proto-js)
gen=gen.coffee
if [ -f "$api_dir/$gen" ]; then
  cd $api_dir
  direnv allow
  direnv exec . ./$gen
fi
