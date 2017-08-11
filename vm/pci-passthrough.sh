#!/bin/bash

# This is intended to provide you with the information necessary to use PCI
# pass-through with a VM. You will need to manually edit the VM's XML
# configuration yourself, however.

usage() {
    echo "usage: $0 <vm-domain-name> <pci-device-address>"
}

if [[ "$#" -lt 2 ]]; then
    usage
    exit 1
fi

vm_domain="$1"
pci_addr="$2"

if [[ "$pci_addr" =~ [0-9]+:[0-9]+:[0-9]+.[0-9]+ ]]; then
    my_pci="$pci_addr"
    domain="${my_pci%%:*}"
    my_pci="${my_pci#$domain}"
    bus="${pci_addr%%:*}"
    slot="${pci_addr%.*}"
    slot="${slot#*:}"
    function="${pci_addr##*.}"
elif [[ "$pci_addr" =~ [0-9]+:[0-9]+.[0-9]+ ]]; then
    domain="0000"
    bus="${pci_addr%%:*}"
    slot="${pci_addr%.*}"
    slot="${slot#*:}"
    function="${pci_addr##*.}"
else
    echo "pci-device-address must be of the form xx:xx:x (bus:slot.function)"
    exit 1
fi


# echo "bus: ${bus}"
# echo "slot: ${slot}"
# echo "function: ${function}"

cat <<EOF
Copy the following XML, then run the following commands and paste the XML into
the VM configuration inside the <devices> tag.

=== XML ===
<hostdev mode='subsystem' type='pci' managed='yes'>
  <source>
      <address domain='0x${domain}' bus='0x${bus}' slot='0x${slot}' function='0x${function}'/>
  </source>
</hostdev>

=== Commands ===
virsh shutdown $vm_domain
virsh edit $vm_domain

EOF
