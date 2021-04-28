#!/bin/bash

# flush de les iptables
iptables -F
iptables -X
iptables -Z
iptables -t nat -F
iptables -t nat -X

#assegurem que podrem fer forward
sysctl -w net.ipv4.ip_forward=1 > /dev/null

#definim les polítiques per defecte
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#interfície loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#nat de sortida i acceptem el trànsit de sortida
iptables -t nat -A POSTROUTING -o eth-troncal -j MASQUERADE
#iptables -A FORWARD -i eth-dmz -o eth-troncal -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate NEW -i eth-dmz -o eth-troncal -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate NEW -i eth-dmz -o eth-dmz -j ACCEPT

#redirecció, nat d'entrada (només dns i ssh a la màquina .11)
iptables -t nat -A PREROUTING -i eth-troncal -p udp --dport 53 -j DNAT --to-destination 10.10.2.4:53
iptables -t nat -A PREROUTING -i eth-troncal -p tcp --dport 22 -j DNAT --to-destination 10.10.2.11:22

#admisió dels paquets redirigits
iptables -A FORWARD -i eth-troncal -p udp --dport 53 -o eth-dmz -m conntrack --ctstate NEW -d 10.10.2.4 -j ACCEPT
iptables -A FORWARD -i eth-troncal -p tcp --dport 22 -o eth-dmz -m conntrack --ctstate NEW -d 10.10.2.11 -j ACCEPT

iptables -A INPUT -p tcp --dport 22 ! -s 10.10.2.11 -j LOG --log-level 4 --log-prefix '[iptables]: type:SSH '
iptables -A INPUT -p icmp --icmp-type 8 -j LOG --log-level 4 --log-prefix '[iptables]: type:ping '