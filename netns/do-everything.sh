#!/bin/bash

usage () {
    echo "usage: $0 <ns> <dev> <addr>"
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

