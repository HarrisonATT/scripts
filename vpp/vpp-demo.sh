#!/bin/bash

if [ "x$1" = "x" ]; then
    dest="vpp"
else
    dest="$1"
fi

set -e
wget https://raw.githubusercontent.com/HarrisonATT/scripts/master/clone-vpp
wget https://raw.githubusercontent.com/HarrisonATT/scripts/master/progressive

./clone-vpp "$dest"
mv progressive "$dest"/build-root/vagrant
cd "$dest"/build-root/vagrant
vagrant up
vagrant ssh -- -t '/vagrant/progressive; /bin/bash --login'
