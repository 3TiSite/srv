#!/usr/bin/env bash

set -ex
name=3tidev
docker stop $name
docker rm $name
