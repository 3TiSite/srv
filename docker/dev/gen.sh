#!/usr/bin/env bash

DIR=$(
  cd "$(dirname "$0")"
  pwd
)
cd $DIR

set -ex

os=${1:-'en'}
rm -f Dockerfile
cp build/$os/Dockerfile Dockerfile
cat build/Dockerfile >>Dockerfile

end=build/$os/end

if [ -f "$end" ]; then
  cat $end >>Dockerfile
fi

cat build/end >>Dockerfile
