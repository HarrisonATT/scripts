#!/bin/bash

sudo ip netns exec ns0 ip addres add 192.122.50.100/24 dev ens7
sudo ip netns exec ns1 ip addres add 192.122.50.101/24 dev ens8
