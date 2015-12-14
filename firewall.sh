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
DMZ="172.16.0.3"
SLAVE="172.16.0.9"

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

# Allows SSH connections to SALTMASTER host

iptables -A INPUT -p tcp -s $SALT --sport 52000 --dport $PA -j ACCEPT
iptables -A OUTPUT -p tcp --sport $PA -d $SALT --dport 52000 -j ACCEPT

# Redirect SSH connection on port 52000 to SALT host on port 52000

iptables -A INPUT -p tcp -s 0/0 --sport $PA -d $SALT --dport 52000 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 52000 -s $SALT -d 0/0 --dport $PA -j ACCEPT
iptables -A FORWARD -p tcp --sport $PA -s 0/0 -d $SALT --dport 52000 -j ACCEPT
iptables -A FORWARD -p tcp --sport 52000 -s $SALT -d 0/0 --dport $PA -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --sport $PA -s 0/0 -d $WAN1 --dport 52000 -j DNAT --to-destination $SALT:52000

# Allows SSH connections to DMZ host

iptables -A INPUT -p tcp -s $DMZ --sport 53000 --dport $PA -j ACCEPT
iptables -A OUTPUT -p tcp --sport $PA -d $DMZ --dport 53000 -j ACCEPT

# Redirect SSH connection on port 53000 to DMZ host on port 53000

iptables -A INPUT -p tcp -s 0/0 --sport $PA -d $DMZ --dport 53000 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 53000 -s $DMZ -d 0/0 --dport $PA -j ACCEPT
iptables -A FORWARD -p tcp --sport $PA -s 0/0 -d $DMZ --dport 53000 -j ACCEPT
iptables -A FORWARD -p tcp --sport 53000 -s $DMZ -d 0/0 --dport $PA -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --sport $PA -s 0/0 -d $WAN1 --dport 53000 -j DNAT --to-destination $DMZ:53000

# Allows SSH connections to SLAVE host

iptables -A INPUT -p tcp -s $SLAVE --sport 59000 --dport $PA -j ACCEPT
iptables -A OUTPUT -p tcp --sport $PA -d $SLAVE --dport 59000 -j ACCEPT

# Redirect SSH connection on port 59000 to SLAVE host on port 59000

iptables -A INPUT -p tcp -s 0/0 --sport $PA -d $SLAVE --dport 59000 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 59000 -s $SLAVE -d 0/0 --dport $PA -j ACCEPT
iptables -A FORWARD -p tcp --sport $PA -s 0/0 -d $SLAVE --dport 59000 -j ACCEPT
iptables -A FORWARD -p tcp --sport 59000 -s $SLAVE -d 0/0 --dport $PA -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --sport $PA -s 0/0 -d $WAN1 --dport 59000 -j DNAT --to-destination $SLAVE:59000

# Accepts DHCP connections from local network.

iptables -A INPUT -p udp --sport 67:68 --dport 67:68 -j ACCEPT
iptables -A OUTPUT -p udp --sport 67:68 --dport 67:68 -j ACCEPT

# Allow FW connect to SALTMASTER.

iptables -A INPUT -p tcp -s $SALT --sport 4505:4506 --dport $PA -j ACCEPT
iptables -A OUTPUT -p tcp --sport $PA -d $SALT --dport 4505:4506 -j ACCEPT

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
#iptables -A INPUT -p icmp -d $WAN2 -j ACCEPT
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

# Redirect all UDP connections on port 53 to DMZ host.

iptables -A INPUT -p udp --sport 53 -s $DMZ -d $FW --dport $PA -j ACCEPT
iptables -A OUTPUT -p udp --sport $PA -s $FW -d $DMZ --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport $PA -s 0/0 -d $DMZ --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -s $DMZ -d 0/0 --dport $PA -j ACCEPT
iptables -t nat -A PREROUTING -p udp --sport $PA -s 0/0 -d $WAN1 --dport 53 -j DNAT --to-destination $DMZ:53

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
