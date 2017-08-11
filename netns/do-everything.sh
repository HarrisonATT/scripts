#!/bin/bash

# This is intended to create a newtork namespace, attach a device to it, and
# then assign an IP address (with prefix/mask) to that device inside the created
# namespace.

# It is also a demonstration of how to use network namespaces so you can know
# what you can do with them.

usage () {
    echo "usage: $0 <ns> <dev> <addr-with-prefix>
example: $0 ns0 eth0 192.168.100.2/24"
}

if [[ $# -lt 3 ]]; then
    usage
    exit 1
fi

ns="$1"
dev="$2"
addr="$3"

echo "ns: ${ns}"
echo "dev: ${dev}"
echo "addr: ${addr}"

set -x
sudo ip netns add "$ns" || true # ok if it already exists
sudo ip link set dev "$dev" netns "$ns"
sudo ip netns exec "$ns" ip link set lo up
sudo ip netns exec "$ns" ip link set "$dev" up
sudo ip netns exec "$ns" ip address add "$addr" dev "$dev"

