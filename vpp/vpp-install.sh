#!/bin/bash

# This is intended to install VPP from the Debian packages. It will not work if
# fd.io is not in the whitelist (which for Chris Chase, it's probably not).

# Allow user to choose installation options
echo "Ubuntu version:"
select ver in "14.04 Trusty" "16.04 Xenial"; do
    case $ver in
        "14.04 Trusty" ) export UBUNTU="trusty"; break;;
        "16.04 Xenial" ) export UBUNTU="xenial"; break;;
    esac
done

echo "VPP release:"
select rel in "17.04" "MASTER" "17.01" "16.09"; do
    case $rel in
        "17.04"  ) export RELEASE="";             break;;
        "MASTER" ) export RELEASE=".master";      break;;
        "17.01"  ) export RELEASE=".stable.1701"; break;;
        "16.09"  ) export RELEASE=".stable.1609"; break;;
    esac
done


# Check for defined environment variables
# http://stackoverflow.com/a/13864829
# RELEASE needs to be set but might be empty
if [[ -z ${UBUNTU} ]] || [[ -z ${RELEASE+x} ]]; then
    echo "Please set the 'UBUNTU' and 'RELEASE' environment variables."
    exit 1
fi


# Install VPP from binaries
# https://wiki.fd.io/view/VPP/Installing_VPP_binaries_from_packages#Ubuntu.2FDebian
sudo rm -f /etc/apt/sources.list.d/99fd.io.list
echo "deb [trusted=yes] https://nexus.fd.io/content/repositories/fd.io$RELEASE.ubuntu.$UBUNTU.main/ ./" | sudo tee -a /etc/apt/sources.list.d/99fd.io.list
sudo apt-get update
sudo apt-get install vpp vpp-dpdk-dkms
