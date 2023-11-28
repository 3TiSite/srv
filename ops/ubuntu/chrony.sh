#!/usr/bin/env bash

set -ex

if ! systemctl is-active --quiet chrony; then
  apt update
  apt install -y chrony
  systemctl enable --now chronyd
else
  echo "chrony service is already active"
fi
