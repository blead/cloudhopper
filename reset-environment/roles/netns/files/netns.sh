#!/usr/bin/env bash

set -x

if [[ $EUID -ne 0 ]]; then
    echo "You must be root to run this script"
    exit 1
fi

# Remove namespace if it exists.
ip netns del $NS &>/dev/null

# Create namespace
ip netns add $NS

# Create a network bridge for our container
brctl addbr ${BRIDGE_NAME}
ip link set ${BRIDGE_NAME} up
ip addr add ${BRIDGE_ADDR}/24 dev ${BRIDGE_NAME}

# Create veth link.
ip link add name ${VETH} type veth peer name ${VPEER}
ip link set ${VETH} up
brctl addif ${BRIDGE_NAME} ${VETH}

# Add peer-1 to NS.
ip link set ${VPEER} netns $NS

# Setup IP ${VPEER}.
ip netns exec $NS ip addr add ${VPEER_ADDR}/24 dev ${VPEER}
ip netns exec $NS ip link set ${VPEER} up
ip netns exec $NS ip link set lo up
ip netns exec $NS ip route add default via ${VETH_ADDR}

# Enable IP-forwarding.
echo 1 > /proc/sys/net/ipv4/ip_forward

# Turn off iptables processing in bridge
echo 0 > /proc/sys/net/bridge/bridge-nf-call-iptables

# Flush forward rules.
# iptables -P FORWARD DROP
# iptables -F FORWARD

# Flush nat rules.
# iptables -t nat -F

# Enable masquerading of 10.200.1.0.
iptables -t nat -A POSTROUTING -s ${VPEER_ADDR}/24 -o eth0 -j MASQUERADE

iptables -A FORWARD -i eth0 -o ${VETH} -j ACCEPT
iptables -A FORWARD -o eth0 -i ${VETH} -j ACCEPT
