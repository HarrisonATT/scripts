#!/bin/bash

# This prints the statistics from devices in a network namespace

echo "=== ns0 ==="
sudo ip netns exec ns0 ip -s address list dev ens7
echo
echo "=== ns1 ==="
sudo ip netns exec ns1 ip -s address list dev ens8

