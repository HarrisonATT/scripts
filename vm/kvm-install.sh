#!/bin/bash

# This is intended to install all packages necessary to use the KVM hypervisor.

# https://www.linux-kvm.org/page/RunningKVM

packages=(gcc
          libsdl1.2-dev
          zlib1g-dev
          libasound2-dev
          linux-kernel-headers
          pkg-config
          libgnutls-dev
          libpci-dev)

sudo apt-get install "${packages[@]}"
