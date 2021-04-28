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
iptables -t nat -A POSTROUTING -o eth-dmz -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate NEW -i eth-servidors -o eth-dmz -j ACCEPT
iptables -A FORWARD -i eth-servidors -o eth-servidors -j ACCEPT

#permís als routers i al monitor de la dmz
iptables -A FORWARD -i eth-dmz -o eth-servidors -s 10.10.2.1 -j ACCEPT
iptables -A FORWARD -i eth-dmz -o eth-servidors -s 10.10.2.2 -j ACCEPT
iptables -A FORWARD -i eth-dmz -o eth-servidors -s 10.10.2.11 -j ACCEPT

iptables -A INPUT -p tcp --dport 22 ! -s 10.10.2.11 -j LOG --log-level 4 --log-prefix '[iptables]: type:SSH '
iptables -A INPUT -p icmp --icmp-type 8 -j LOG --log-level 4 --log-prefix '[iptables]: type:ping '