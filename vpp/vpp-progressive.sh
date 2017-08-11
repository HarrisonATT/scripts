#!/bin/bash

# This is intended to run the VPP Progressive tutorial as found at the following
# page:
# https://wiki.fd.io/view/VPP/Progressive_VPP_Tutorial

##############################################
## Preparation: Ensure superuser privileges ##
##############################################
if [ "$USER" != "root" ]; then
    echo "Restarting script with sudo.."
    sudo "$0" "$@"
    exit
fi

##################################
## Preparation: Local variables ##
##################################
half_stars="****************************************"
stars="${half_stars}${half_stars}"
footer="


${stars}

"


#######################################
## Preparation: Clear existing state ##
#######################################
pgrep -ef vpp | grep -v grep | awk '{print $2}'| xargs -r sudo kill
sudo ip link del dev vpp1host
sudo ip link del dev vpp1vpp2


#############################
## Preparation: Bash setup ##
#############################
echo "This will use the read command to pause until you want to continue"
set -e # exit if any subcommand is unsuccessful
set -x # echo commands before they run


##########################
## Exercise: vpp basics ##
##########################
# Action: Run vpp
vpp api-segment '{' prefix vpp1 '}'
# Action: Using vppctl to send commands to vpp
vppctl -p vpp1 show ver
read
echo "${footer}"


###################################
## Exercise: Create an Interface ##
###################################
# Action: Create veth interfaces on host
ip link add name vpp1out type veth peer name vpp1host
ip link set dev vpp1out up
ip link set dev vpp1host up
ip addr add 10.10.1.1/24 dev vpp1host
ip addr show vpp1host
# Action: Create vpp host- interface
vppctl -p vpp1 create host-interface name vpp1out
vppctl -p vpp1 show hardware
vppctl -p vpp1 set int state host-vpp1out up
vppctl -p vpp1 show int
vppctl -p vpp1 set int ip address host-vpp1out 10.10.1.2/24
vppctl -p vpp1 show int addr
# Action: Add trace
vppctl -p vpp1 trace add af-packet-input 10
# Action: Ping from host to vpp
ping -c 1 10.10.1.2
# Action: Examine Trace of ping from host to vpp
vppctl -p vpp1 show trace
# Action: Clear trace buffer
vppctl -p vpp1 clear trace
# Action: ping from vpp to host
vppctl -p vpp1 ping 10.10.1.1
# Action: Examine Trace of ping from vpp to host
vppctl -p vpp1 show trace
vppctl -p vpp1 clear trace
# Action: Examine arp tables
vppctl -p vpp1 show ip arp
# Action: Examine routing table
vppctl -p vpp1 show ip fib
read
echo "${footer}"


###################################
## Exercise: Create an Interface ##
###################################
# Action: Running a second vpp instances
vpp api-segment '{' prefix vpp2 '}'
# Action: Create veth interface on host to connect the two vpp instances
ip link add name vpp1vpp2 type veth peer name vpp2vpp1
ip link set dev vpp1vpp2 up
ip link set dev vpp2vpp1 up
# Action: Create vpp host interfaces
vppctl -p vpp1 create host-interface name vpp1vpp2
vppctl -p vpp1 set int state host-vpp1vpp2 up
vppctl -p vpp1 set int ip address host-vpp1vpp2 10.10.2.1/24
vppctl -p vpp2 create host-interface name vpp2vpp1
vppctl -p vpp2 set int state host-vpp2vpp1 up
vppctl -p vpp2 set int ip address host-vpp2vpp1 10.10.2.2/24
# Action: Ping from vpp1 to vpp2
vppctl -p vpp1 ping 10.10.2.2
vppctl -p vpp2 ping 10.10.2.1
read
echo "${footer}"


#######################
## Exercise: Routing ##
#######################
# Action: Setup host route
sudo ip route add 10.10.2.0/24 via 10.10.1.2
ip route
# Setup return route on vpp2
sudo vppctl -p vpp2 ip route add 10.10.1.0/24  via 10.10.2.1
# Ping from host through vpp1 to vpp2
#   1. Setup a trace on vpp1 and vpp2
sudo vppctl -p vpp1 trace add af-packet-input 10
sudo vppctl -p vpp2 trace add af-packet-input 10
#   2. Ping 10.10.2.2 from the host
ping -c 1 10.10.2.2
#   3. Examine the trace on vpp1 and vpp2
vppctl -p vpp1 show trace
vppctl -p vpp2 show trace
#   4. Clear the trace on vpp1 and vpp2
vppctl -p vpp1 clear trace
vppctl -p vpp2 clear trace
# Ping from vpp2 through vpp1 to host
#   1. Setup the trace on vpp1 and vpp2
sudo vppctl -p vpp1 trace add af-packet-input 10
sudo vppctl -p vpp2 trace add af-packet-input 10
#   2. Ping 10.10.1.1 from vpp2
vppctl -p vpp2 ping 10.10.1.1
#   3. Examine the trace on vpp1 and vpp2
vppctl -p vpp1 show trace
vppctl -p vpp2 show trace
#   4. Clear the trace on vpp1 and vpp2
vppctl -p vpp1 clear trace
vppctl -p vpp2 clear trace
