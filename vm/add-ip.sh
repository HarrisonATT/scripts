#!/bin/bash

usage() {
    cat <<-EOF
			usage: $0 <last-part-of-address> [<dev-name>]

			ex. $0 101      # Add address 192.168.100.101 to ens6 (default)
			    $0 102 ens7 # Add address 192.168.100.101 to ens7
			EOF
    exit 1
}

if [[ "$#" -lt 1 ]]; then
    usage
fi

addr="$1"

if [[ "$#" -eq 2 ]];then
    dev="$2"
else
    dev="ens6"
fi

sudo ip link set dev "$dev" up
sudo ip address add 192.168.100.${addr}/24 dev "$dev"
sudo ip route add 192.168.100.0/24 dev "$dev"
