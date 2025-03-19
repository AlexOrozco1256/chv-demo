#!/bin/bash

sudo ip link add name vrb0 type bridge
sudo ip link set dev vrb0 up
sudo ip addr add 192.168.111.11/24 dev vrb0

sudo ip tuntap add tap1234 mode tap
sudo ifconfig tap1234 0.0.0.0 promisc up
sudo ip link set dev tap1234 master vrb0
sudo ip link set dev tap1234 up
sudo ip link set dev vrb0 up

sudo setcap cap_net_admin+ep ./cloud-hypervisor

sudo chmod 777 /dev/sev