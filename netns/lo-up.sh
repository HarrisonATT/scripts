#!/bin/bash

# Turn up the loopback interface inside of a network namespace.

# This seems pointless but there were some times were things weren't working and
# this helped for some reason.

sudo ip netns exec ns0 ip link set dev lo up
sudo ip netns exec ns1 ip link set dev lo up

