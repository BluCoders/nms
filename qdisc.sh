#!/bin/bash

. /etc/rc.conf
. /etc/rc.d/functions

DEV=eth-inet
CEIL=40mbit

stat_busy "Setting qdiscs"
tc qdisc del dev $DEV root &>/dev/null
tc qdisc add dev $DEV root handle 1: htb default 22

tc class add dev $DEV parent 1: classid 1:1 htb rate 1000mbit ceil 1000mbit
tc class add dev $DEV parent 1: classid 1:2 htb rate $CEIL ceil $CEIL
	tc class add dev $DEV parent 1:2 classid 1:20 htb rate $CEIL ceil $CEIL
	tc class add dev $DEV parent 1:2 classid 1:21 htb rate 30mbit ceil $CEIL
	tc class add dev $DEV parent 1:2 classid 1:22 htb rate 1kbit ceil $CEIL

tc qdisc add dev $DEV parent 1:20 handle 20: sfq perturb 10
tc qdisc add dev $DEV parent 1:21 handle 21: sfq perturb 10
tc qdisc add dev $DEV parent 1:22 handle 22: sfq perturb 10


# Filter
FCMD="tc filter add dev $DEV protocol ip parent 1:0 "
$FCMD prio 1 handle 1 fw classid 1:20	## rt
$FCMD prio 2 handle 2 fw classid 1:21	## high
$FCMD prio 3 handle 3 fw classid 1:22	## low
$FCMD prio 4 handle 4 fw classid 1:1	## local

# iptables
iptables -t mangle -F
iptables -t mangle -X
iptables -t mangle -Z
iptables -t mangle -A OUTPUT	-p udp --dport 53			-j MARK --set-mark 0x1	## dns is high
iptables -t mangle -A OUTPUT	-p udp --sport 53			-j MARK --set-mark 0x1	## dns is high
iptables -t mangle -A OUTPUT	-p tcp --sport 22			-j MARK --set-mark 0x1	## ssh in is high
iptables -t mangle -A OUTPUT	-p tcp --sport 655			-j MARK --set-mark 0x1	## tinc is high
iptables -t mangle -A OUTPUT	-p tcp --dport 655			-j MARK --set-mark 0x1	## tinc is high
iptables -t mangle -A OUTPUT	-p udp --sport 655			-j MARK --set-mark 0x1	## tinc is high
iptables -t mangle -A OUTPUT	-p udp --sport 1023			-j MARK --set-mark 0x2	## openvpn is med
iptables -t mangle -A OUTPUT	-p tcp --dport 7002			-j MARK --set-mark 0x1	## inspircd server prio
iptables -t mangle -A OUTPUT	-p tcp --sport 6667			-j MARK --set-mark 0x2	## inspircd
iptables -t mangle -A OUTPUT	-p tcp --sport 6697			-j MARK --set-mark 0x2	## inspircd
iptables -t mangle -A OUTPUT	-p icmp					-j MARK --set-mark 0x2

iptables -t mangle -A FORWARD	-p tcp --dport 21			-j MARK --set-mark 0x2	## ftp is cool
iptables -t mangle -A FORWARD	-p tcp --dport 22			-j MARK --set-mark 0x2	## ssh is cool
iptables -t mangle -A FORWARD	-p udp --dport 53			-j MARK --set-mark 0x1	## dns is cool		# But provided by gamma
iptables -t mangle -A FORWARD	-p tcp --dport 80			-j MARK --set-mark 0x2	## Http responsiveness
iptables -t mangle -A FORWARD	-p tcp --dport 443			-j MARK --set-mark 0x2	## Https responsiveness
iptables -t mangle -A FORWARD	-p icmp					-j MARK --set-mark 0x2


#iptables -t mangle -A FORWARD	-p tcp --dport 3074			-j MARK --set-mark 0x2	## Xbox live
#iptables -t mangle -A FORWARD	-p tcp --dport 4070			-j MARK --set-mark 0x2	## Spotify
#iptables -t mangle -A FORWARD	-p tcp --dport 25565			-j MARK --set-mark 0x2	## Minecraft
#iptables -t mangle -A FORWARD	-p tcp --dport 2099			-j MARK --set-mark 0x2	## League of Legends
#iptables -t mangle -A FORWARD	-p tcp --dport 5223			-j MARK --set-mark 0x2	## League of Legends
#iptables -t mangle -A FORWARD	-p tcp --dport 5222			-j MARK --set-mark 0x2	## League of Legends

# NOTE: These are things prioritized because their ownership changes to gamma
#	- IPv6
#	- VPN traffic
#	- Tinc

ip6tables -t mangle -F
ip6tables -t mangle -X
ip6tables -t mangle -Z

ip6tables -t mangle -A OUTPUT	-p tcp --sport 6667			-j MARK --set-mark 0x2	## inspircd
ip6tables -t mangle -A OUTPUT	-p tcp --sport 6697			-j MARK --set-mark 0x2	## inspircd
#ip6tables -t mangle -A FORWARD -j MARK --set-mark 0x2
#ip6tables -t mangle -A OUTPUT -j MARK --set-mark 0x2

stat_done
