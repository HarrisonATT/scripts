#!/bin/bash

# This script is intended to install all of the necessary packages and then
# download and install VirtualBox.

pkg="virtualbox-5.1_5.1.22-115126~Ubuntu~xenial_amd64.deb"
url="http://download.virtualbox.org/virtualbox/5.1.22/${pkg}"

wget "${url}"
sudo dpkg -i "${pkg}"
