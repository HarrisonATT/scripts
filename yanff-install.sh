#!/bin/bash

#################
# Install YANFF #
#################

# See https://github.com/intel-go/yanff
# Based on README as it was at this commit:
# https://github.com/intel-go/yanff/blob/46faf2195ed1303da13d5d8c748188f6f37816a4/README.md

# Check run requirements
########################

# Ensure go is installed
go version >& /dev/null || {
    echo "go not installed"
    echo "You can download it here: https://golang.org/doc/install"
    echo "Or use an installation script here: https://github.com/canha/golang-tools-install-script"
    echo "  -note: you must change the version from 1.7.1 to 1.8.x"
    exit 1
}

# Ensure go is at least required version
reqver=1.8
ver=$(go version | sed -nr 's/.*go([0-9]\.[0-9]).*/\1/p')
# ver=$(go version | awk '{ print $3 }')
# ver=${ver/go/}
# ver=${ver%.*}
awk -v ver="${ver}" -v reqver="${reqver}" 'BEGIN { if (ver < reqver) exit 1 }' || {
    echo "go must be at least version $reqver"
    exit 1
}

# Ensure required packages are installed
# git          : for `go get ...`
# libpcap-dev  : libpcap headers for DPDK
# gcc-multilib : for DPDK
# xz-utils     : to decompress DPDK download
sudo apt-get install git libpcap-dev gcc-multilib xz-utils || {
    echo "Need to have git, libpcap headers, gcc-multilib, and xz-utils"
}


# Install YANFF
###############

# Bail out if anything goes wrong
set -e

GOPATH=$(go env GOPATH)

# Download Docker sources
go get -v -d github.com/docker/docker/api
# Go to $GOPATH/src/github.com/docker/docker/vendor/github.com/docker and delete
# directory named "go-connections."
rm -rf "${GOPATH}/src/github.com/docker/docker/vendor/github.com/docker/go-connections"
# Install go-connections dependencies:
go get -v github.com/Sirupsen/logrus
go get -v github.com/pkg/errors
# Install proxy support
go get -v golang.org/x/net/proxy
# Install go-connections from its mainstream repository
go get -v github.com/docker/go-connections
# Build docker from sources
go install github.com/docker/docker/api
# Install stringer code generator
go get -v golang.org/x/tools/cmd/stringer
# Set your PATH to point to bin directory under your GOPATH, e.g. export
# PATH="$PATH:$GOPATH"/bin
echo "$PATH" | tr ':' '\n' | grep "${GOPATH}/bin" || \
    echo 'export PATH="$PATH:$(go env GOPATH)/bin"' >> ~/.bashrc
# You should be able to build test framework now with "make main" in test
# sub-directory.
go get -v -d github.com/intel-go/yanff \
    || true # complains about no buildable packages

# This is supposed to run by default, but just in case
# It won't run again after the first time, even if it fails
(cd "${GOPATH}/src/github.com/intel-go/yanff/test" && go generate)

(cd "${GOPATH}/src/github.com/intel-go/yanff/test" && make all)
