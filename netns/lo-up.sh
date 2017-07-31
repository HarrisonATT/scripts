#!/bin/bash

sudo ip netns exec ns0 ip link set dev lo up
sudo ip netns exec ns1 ip link set dev lo up

