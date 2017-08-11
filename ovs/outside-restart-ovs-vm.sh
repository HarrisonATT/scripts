#!/bin/bash

# This script was given to me by Chang Xu. I've never used it, but it may
# provide some useful insight.

# rmmod ixgbevf
#/etc/init.d/openvswitch-ipsec stop
/etc/init.d/openvswitch-switch stop
#/etc/init.d/openvswitch-vtep stop
export DPDK_DIR=/root/ovs27/dpdk-16.11.1
export DPDK_BUILD=$DPDK_DIR/x86_64-native-linuxapp-gcc/

#OVS_DIR=/root/ovs26/ovs-master
/sbin/modprobe igb_uio
/sbin/modprobe vfio_pci
/bin/chmod a+x /dev/vfio
/bin/chmod 0666 /dev/vfio/*


#insmod $DPDK_DIR/lib/librte_vhost/eventfd_link/eventfd_link.ko
#umount /dev/hugepages
#mkdir -p /mnt/huge

#umount /mnt/huge
#mkdir -p /mnt/huge_2mb
#mount -t hugetlbfs hugetlbfs /mnt/huge
#mount -t hugetlbfs none /mnt/huge_2mb -o pagesize=2MB
#ip link set dev eth1 up
sleep 5
/usr/local/share/dpdk/tools/dpdk_nic_bind.py --status
## virtual function not working
#/usr/bin/dpdk_nic_bind.py -u  03:00.0
#/usr/bin/dpdk_nic_bind.py -b vfio-pci  03:00.0

/usr/local/share/dpdk/tools/dpdk_nic_bind.py -b vfio-pci 01:00.0
/usr/local/share/dpdk/tools/dpdk_nic_bind.py -b vfio-pci 01:00.1
#/usr/bin/dpdk_nic_bind.py -u 01:00.0
#/usr/bin/dpdk_nic_bind.py -u 01:00.1

#/usr/local/share/dpdk/tools/dpdk_nic_bind.py -b vfio-pci 02:00.1

##
/usr/local/share/dpdk/tools/dpdk_nic_bind.py --status
#/usr/bin/dpdk_nic_bind.py -u  07:11.5
#/usr/bin/dpdk_nic_bind.py -b vfio-pci  07:11.5
#/usr/bin/dpdk_nic_bind.py -b igbvf  07:11.5
#/usr/bin/dpdk_nic_bind.py -b igb_uio  07:11.5

sleep 5

#dpdk_nic_bind.py --bind=igb_uio 03:05.0
#dpdk_nic_bind.py --bind=igb_uio 03:06.0
#mount -t hugetlbfs nodev /mnt/huge
#echo 64 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages

#mkdir -p /usr/local/etc/openvswitch
#      mkdir -p /usr/local/var/run/openvswitch
#      rm -f /usr/local/etc/openvswitch/conf.db
#      /usr/local/bin/ovsdb-tool create /usr/local/etc/openvswitch/conf.db  /root/ovs26/openvswitch-2.6.1/vswitchd/vswitch.ovsschema


/usr/local/sbin/ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock --remote=db:Open_vSwitch,Open_vSwitch,manager_options --pidfile --detach
#$OVS_DIR/ovsdb/ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
#          --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
#          --private-key=db:Open_vSwitch,SSL,private_key \
#          --certificate=Open_vSwitch,SSL,certificate \
#          --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert --pidfile --detach

sleep 1
modprobe openvswitch
sleep 10
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
/usr/local/bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
/usr/local/bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:pmd-cpu-mask=0xc
#   /usr/local/bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask=0x2
#   /usr/local/bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:vhost-sock-dir=
/usr/local/bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="2048,0"
/usr/local/bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-hugepage-mem=/dev/hugepages
#/usr/local/bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-hugepage-mem=/mnt/huge
#  /usr/local/bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true

#/usr/bin/dpdk_nic_bind.py -u 06:00.0
/usr/local/sbin/ovs-vswitchd   unix:$DB_SOCK --pidfile --detach  --log-file=/var/log/openvswitch/ovs-vswitchd.log
#/usr/bin/dpdk_nic_bind.py -b igb 06:00.0

#$OVS_DIR/vswitchd/ovs-vswitchd --dpdk -c 0x1 -n 4 -b 0000:02:04.0 --socket-mem 1024 -- unix:/usr/local/var/run/openvswitch/db.sock --pidfile --detach  --log-file=/var/log/openvswitch/ovs-vswitchd.log
