#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -ex

[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

export DEBIAN_FRONTEND=noninteractive

sed -i 's/^Prompt=.*/Prompt=normal/' /etc/update-manager/release-upgrades

apt update

apt --fix-broken install -y

apt autoremove -y

apt remove -y sg3-utils sg3-utils-udev multipath-tools ubuntu-server

apt upgrade -y

apt install update-manager-core -y

now_en=$(lsb_release -c | awk '{print $NF}')
new_ver=$(do-release-upgrade -c | grep -oP "(\d+\.\d+)") || exit 0
new_en=$(curl -s https://changelogs.ubuntu.com/meta-release | grep "Version: $new_ver" -B3 | grep "Dist:" | awk '{print $NF}')

sed -i "s/$now_en/$new_en/g" /etc/apt/sources.list

apt update

apt upgrade -y || true

apt dist-upgrade -y || true

apt autoremove -y

cat /etc/os-release
