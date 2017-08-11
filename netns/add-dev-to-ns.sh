#!/bin/bash

# How to attach a device to a network namespace

sudo ip link set dev ens7 netns ns0
sudo ip link set dev ens8 netns ns1
