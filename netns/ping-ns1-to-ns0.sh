#!/bin/bash

# This script is a test to ping from one network namespace to another

sudo ip netns exec ns1 ping 192.122.50.100
