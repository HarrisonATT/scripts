#!/bin/bash

# List all devices inside a network namespace

echo "=== ns0 ==="
sudo ip netns exec ns0 ip address list
echo
echo "=== ns1 ==="
sudo ip netns exec ns1 ip address list

