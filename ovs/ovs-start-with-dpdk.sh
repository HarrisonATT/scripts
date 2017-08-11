#!/bin/bash

# This script is intended to start OVS with DPDK support. It is mostly based on
# the following page:
# http://docs.openvswitch.org/en/latest/intro/install/dpdk/#setup-ovs

set -e
set -x
# ovs-ctl may not be in the path for sudo
ovs_ctl_script="$(which ovs-ctl)"

ovs_dir="/usr/local/etc/openvswitch"
export DB_SOCK="${ovs_dir}/db.sock"

# start ovdb-server
sudo "$ovs_ctl_script" --no-ovs-vswitchd start
# configure ovs-vswitchd
sudo ovs-vsctl --no-wait set Open_vSwitch . \
     other_config:dpdk-init="true"
sudo ovs-vsctl --no-wait set Open_vSwitch . \
     other_config:dpdk-socket-mem="2048,2048"
# We're just going to use the default database socket. Feel free to use this if
# you want to.
# sudo "$ovs_ctl_script" --no-ovsdb-server --db-sock="$DB_SOCK" start
sudo "$ovs_ctl_script" --no-ovsdb-server start


# There are many other configuration options, the most important of which are
# listed below. Defaults will be provided for all values not explicitly set.

# dpdk-init
#   Specifies whether OVS should initialize and support DPDK ports. This is a
#   boolean, and defaults to false.

# dpdk-lcore-mask
#   Specifies the CPU cores on which dpdk lcore threads should be spawned and
#   expects hex string (eg '0x123eg').

# dpdk-socket-mem
#   Comma separated list of memory to pre-allocate from hugepages on specific
#   sockets.

# dpdk-hugepage-dir
#   Directory where hugetlbfs is mounted.

# vhost-sock-dir
#   Option to set the path to the vhost-user unix socket files.
