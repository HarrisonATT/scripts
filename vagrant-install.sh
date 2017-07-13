#!/bin/bash

ver="1.9.7"
arch="x86_64"
url="https://releases.hashicorp.com/vagrant/${ver}/vagrant_${ver}_${arch}.deb"
pkg="vagrant_${ver}_${arch}.deb"

wget "${url}"
sudo dpkg -i "${pkg}"
