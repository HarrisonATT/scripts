#!/bin/bash

sudo ip link set dev ens7 netns ns0
sudo ip link set dev ens8 netns ns1
