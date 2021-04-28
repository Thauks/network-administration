#!/bin/bash
#Redirecciona la sortida estàndar al fitxer info_eth.txt
exec 1>info_eth.txt

#Funció que omple l'array usrs amb els usuaris que tenen un shell
USRS() {
	len=$(cat /etc/passwd | wc -l | bc)
	i=1
	while [[ "$i" -le "$len" ]]
	do
		sentence=$(sed "${i}q;d" /etc/passwd | cut -d: -f7)
		adder=$(sed "${i}q;d" /etc/passwd | cut -d: -f1)
		if [[ $sentence == "/bin/bash" || $sentence == "/bin/sh" ]]; then
			usrs+=$adder" "
		fi
		>/dev/null echo -e -n "$[i+=1]"
	done
}
#Calcula l'adreça de xarxa amb els dos paràmetres que se li passen
#S'espera una Mascara i una ip si algun dels dos camps és buit salta error
netaddr_calc() {
	if [[ "$1" != "" && "$2" != "" ]]; then
		ip1=$(echo -e -e $1 | cut -d. -f1)
		ip2=$(echo -e -e $1 | cut -d. -f2)
		ip3=$(echo -e -e $1 | cut -d. -f3)
		ip4=$(echo -e -e $1 | cut -d. -f4)

		nm1=$(echo -e -e $2 | cut -d. -f1)
		nm2=$(echo -e -e $2 | cut -d. -f2)
		nm3=$(echo -e -e $2 | cut -d. -f3)
		nm4=$(echo -e -e $2 | cut -d. -f4)

		netaddr=$(($nm1&$ip1)).$(($nm2&$ip2)).$(($nm3&$ip3)).$(($nm4&$ip4))
	else
		echo -e "		ATENCIO! IP o Mascara no valides"
	fi
}

#Comprovació de si l'script s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo -e "Script disponible nomes amb permis de root" 1>&2
   exit 1
fi

#Crida de la funció USRS per a omplir l'array
USRS

#Variables que s'omplen amb el resultat de comandes que ens proporcionen la info
#desitjada. Els noms de les variables coincideixen amb la dada que contenen.
date=$(date)
hostname=$(hostname)
routerip=$(ip route show | grep -i 'default via'| awk '{print $3 }')
extip=$(wget http://ipinfo.io/ip -qO -)
dns=$(cat /etc/resolv.conf | grep nameserver | cut -d' ' -f2)
var=$(ifconfig | grep encap | cut -d' ' -f1)

#Impressio de les dades de l'equip
echo -e "========================================================================="
echo -e "|         NetStat and NetInfo Script By: Jordi Mestres. SEAX		|"
echo -e "========================================================================="
echo -e "	Dades de l'equip"
echo -e
echo -e "	Data:				"$date
echo -e "	Usuaris Humans:		 	"${usrs}
echo -e "	Hostname:			"$hostname
echo -e "	Addr IP del router:		"$routerip
echo -e "	Addr IP externa:		"$extip
echo -e "	Addr dels DNSs:			"$dns

#Recoleccio i print de les dades per a cada Interficie
for iface in $var
	do
		if [[ $iface != "lo" ]]; then
			echo -e
			echo -e "	Interficie: " $iface
			echo -e "		Addr MAC:		" `cat /sys/class/net/$iface/address`
			if [[ `cat /sys/class/net/$iface/operstate` == "up" ]]; then
				echo -e "		INTERFICIE ACTIVA "
				ip=$(ifconfig $iface | grep 'inet addr:' |cut -d: -f2 |cut -d' ' -f1)
				#Obtenir el nom del domini mitjançant dig
				: '
				if [[ "$1" != "" ]]; then
					dnss=$(dig -x $ip +short)
				else
					dnss=""
				fi
				'
				#Obtenir el nom del domini mitjançant /etc/resolv.conf
				dnss=$(cat /etc/resolv.conf | grep domain | cut -d' ' -f2)

				#Variables que emmagatzemen la informació de la interficie. Intuitives
				netmask=$(ifconfig $iface | grep 'Mask:' |cut -d: -f4 |cut -d' ' -f1)
				bcast=$(ifconfig $iface | grep 'Bcast:' |cut -d: -f3 |cut -d' ' -f1)
				netaddr_calc $ip $netmask
				netname=$(cat /etc/networks | grep $netaddr | cut -d$'\t' -f1)
				netdns=$()
				MTU=$(ifconfig $iface | grep 'MTU:' |cut -d: -f2 |cut -d' ' -f1)

				echo -e "		Addr IP:		" $ip
				echo -e "		Nom DNS:		" $dnss
				echo -e "		Mascara de xarxa:	" $netmask
				echo -e "		Addr de xarxa:		" $netaddr
				echo -e "		Nom de la xarxa:	" $netname
				echo -e "		Nom Dns de la xarxa	" $netdns
				echo -e "		MTU:			" $MTU
			else
				echo -e "		INTERFICIE INACTIVA "
			fi
		fi
	done
echo -e "========================================================================="
