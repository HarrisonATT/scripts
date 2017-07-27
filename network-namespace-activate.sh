#!/bin/bash
# https://blogs.igalia.com/dpino/2016/04/10/network-namespaces/
_ns_name="$1"
if [[ -z "$1" ]]; then
    _ns_name="netns0"
fi
if ! ip netns list | grep "$_ns_name" -q; then
    sudo ip netns add "$_ns_name"
fi
sudo ip netns exec "$_ns_name" bash --rcfile \
     <(echo "PS1=\"namespace $_ns_name> \"")
unset _ns_name
