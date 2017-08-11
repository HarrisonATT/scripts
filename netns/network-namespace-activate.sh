#!/bin/bash
# This is intended to create a bash shell that is "inside" a network
# namespace. It will set the PS1 to remind you that you are in the network
# namespace.

# This script is mostly based on the following page:
# https://blogs.igalia.com/dpino/2016/04/10/network-namespace/

if [ "$USER" != "root" ]; then
    echo "Restarting script with sudo.."
    sudo "$0" "$@"
    exit
fi

_ns_name="$1"
if [[ -z "$1" ]]; then
    _ns_name="netns0"
fi
if ! ip netns list | grep "$_ns_name" -q; then
    ip netns add "$_ns_name"
fi
ip netns exec "$_ns_name" bash --rcfile \
   <(echo "PS1=\"namespace $_ns_name> \"")
unset _ns_name
