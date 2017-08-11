#!/bin/bash

# This script is intended to be run once after you clone a VM to give it a new
# name instead of inheriting the name of the VM it was cloned from.

# This changes the "domain" or "host" name for a Ubuntu machine. This will
# change what name your computer calls itself (i.e. user@machine-name) and also
# what domain it calls its loopback domain. This affects how the prompt looks
# when you log in and the "domain" listed when you run `virsh net-dhcp-leases
# <net-name>`.

usage() {
    echo "usage: $0 <new-domain-name>"
    exit 1
}

if [[ "$#" != 1 ]]; then
    usage
fi

name="$1"
old=$(hostname)
echo "$name" | sudo tee /etc/hostname
sudo sed -i "s/$old/$name/" /etc/hosts
sudo hostname "$name"
sudo service networking restart
