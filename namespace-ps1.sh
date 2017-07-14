#!/bin/bash
# https://blogs.igalia.com/dpino/2016/04/10/network-namespaces/
_ns_name="netns0"
ip netns exec netns0 bash <(echo "PS1=\"namespace $_ns_name> \"")
unset _ns_name
