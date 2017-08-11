#!/bin/bash

# This is intended to clone the VPP git code base. It's pretty unnecessary, I'm
# not sure why I made it.

set -e
if [ "x$1" = "x" ]; then
    dest="vpp"
else
    dest="$1"
fi

git clone https://gerrit.fd.io/r/vpp "$dest"
# cd "$dest"
# ./build-root/vagrant/build.sh

