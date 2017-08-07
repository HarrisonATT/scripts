#!/bin/bash

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
