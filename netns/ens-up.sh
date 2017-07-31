#!/bin/bash

sudo ip netns exec ns0 ip link set dev ens7 up
sudo ip netns exec ns1 ip link set dev ens8 up
