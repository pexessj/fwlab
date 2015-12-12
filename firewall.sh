#!/bin/bash

### BEGIN INIT INFO
# Provides:		firewall
# Required-Start:	
# Required-Stop:	
# Default-Start:	2 3 4 5
# Default-Stop:		
# Short-Description:	Firewall Script developed by Matheus Carino
### END INIT INFO

## Variables

WAN1="192.168.0.254"
WAN2=""
FW="172.16.0.1"
LAN="172.16.0.0/24"
PA="1024:65535"
SALT="172.16.0.2"

## Rules

case $1 in 

stop)

# Change all policies to ACCEPT.

iptables -P OUTPUT ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT

# Clean all the rules of the NAT and FILTER tables.

iptables -t nat -F
iptables -t filter -F

;;

start)

# Change all policies to DROP.

iptables -P OUTPUT DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP

# Accepts external access by SSH service on port 22 from any source.

iptables -A INPUT -p tcp -s 0/0 -d $WAN1 --dport 22 -j ACCEPT 
iptables -A OUTPUT -p tcp -s $WAN1 -d 0/0 --dport $PA -j ACCEPT 

# Accepts SSH connections to anywhere.

iptables -A INPUT -p tcp --sport 22 --dport $PA -j ACCEPT
iptables -A OUTPUT -p tcp --sport $PA --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --sport 52000 --dport $PA -j ACCEPT
iptables -A OUTPUT -p tcp --sport $PA --dport 52000 -j ACCEPT

# Accepts HTTP connections to the internet.

iptables -A INPUT -p tcp -s 0/0 --sport 80 -d $WAN1 --dport $PA -j ACCEPT
iptables -A OUTPUT -p tcp -s $WAN1 --sport $PA -d 0/0 --dport 80 -j ACCEPT

# Accepts HTTPS connections to the internet.

iptables -A INPUT -p tcp -s 0/0 --sport 443 -d $WAN1 --dport $PA -j ACCEPT
iptables -A OUTPUT -p tcp -s $WAN1 --sport $PA -d 0/0 --dport 443 -j ACCEPT

# Accepts DNS connections to the internet.

iptables -A INPUT -p udp -s 0/0 --sport 53 -d $WAN1 --dport $PA -j ACCEPT
iptables -A OUTPUT -p udp -s $WAN1 --sport $PA -d 0/0 --dport 53 -j ACCEPT

# Accepts any ICMP connections to the anywhere.

iptables -A OUTPUT -p icmp -d 0/0 -j ACCEPT
iptables -A INPUT -p icmp -d 127.0.0.1 -j ACCEPT
iptables -A INPUT -p icmp -d $WAN1 -j ACCEPT
iptables -A INPUT -p icmp -d $WAN2 -j ACCEPT
iptables -A INPUT -p icmp -d $FW -j ACCEPT


# NAT configuration for local hosts access to the internet

iptables -t nat -I POSTROUTING -o eth0 -s $LAN -j MASQUERADE

# Accepts HTTP,HTTPS,FTP,SSH connections from local hosts to the internet.
for tcp_service in 20 21 22 80 443
do
iptables -A FORWARD -p tcp --sport $tcp_service -s 0/0 -d $LAN --dport $PA -j ACCEPT
iptables -A FORWARD -p tcp --sport $PA -s $LAN -d 0/0 --dport $tcp_service -j ACCEPT
done

# Accepts DNS connections from local hosts to the internet.
for udp_service in 53
do
iptables -A FORWARD -p udp --sport $udp_service -s 0/0 -d $LAN --dport $PA -j ACCEPT
iptables -A FORWARD -p udp --sport $PA -s $LAN -d 0/0 --dport $udp_service -j ACCEPT
done

# Accepts any ICMP connections from local hosts to the internet.
iptables -A FORWARD -p icmp -s 0/0 -d $LAN -j ACCEPT
iptables -A FORWARD -p icmp -s $LAN -d 0/0 -j ACCEPT

;;

restart)

$0 stop
sleep 0.5
$0 start


;;

*)

echo 'Please use one of the following "START | STOP | RESTART"'

;;

esac
