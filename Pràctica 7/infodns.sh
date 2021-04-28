#!/bin/bash

# Assignació d'adreça del servidor
DNS=10.0.0.3

# Comprovació de la instalació de dig
command -v dig &>/dev/null
if [ $? != 0 ]; then
	echo "Falten eines per a executar l'script. (dnsutils)"
	echo "sudo apt-get install dnsutils"
	exit 0
fi

# Usage
if [ $# -lt 1 ]; then
	echo -e "Error de parametres: $0 domini"
	exit 0
fi

# Comprovació d'operativitat del DNS
ping -c 1 $DNS &>/dev/null
if [ $? != 0 ]; then
	echo "Error: No es troba DNS..."
	exit 1
fi

echo -e "\n Domini: $1"
echo "________________________________________________________________________________________"
# informació general del domini
names=$(dig +short @$DNS -t NS $1)
echo -e "\n - Informacio general del domini"
for name in $names; do
	ip4=$(dig +short @$DNS -t A $name)
	ip6=$(dig +short @$DNS -t AAAA $name)
	echo -e "\t$name\t-->\tipv4: $ip4\tipv6: $ip6"
done

#informació del start of authority

echo -e "\n - Start of Authority"
soa=$(dig +short @$DNS -t SOA $1)
echo -e "\tServidor Primari: \t\t$(echo $soa| cut -d' ' -f1)"
echo -e "\tResponsable del domini: \t$(echo $soa| cut -d' ' -f2)"
echo -e "\tSerial: \t\t\t$(echo $soa| cut -d' ' -f3)"
echo -e "\tRefresh: \t\t\t$(echo $soa| cut -d' ' -f4)"
echo -e "\tRetry: \t\t\t\t$(echo $soa| cut -d' ' -f5)"
echo -e "\tExpires: \t\t\t$(echo $soa| cut -d' ' -f6)"
echo -e "\tNegative cache TTL: \t\t$(echo $soa| cut -d' ' -f7)"

# servidors de correu
mail=$(dig +short @$DNS -t MX $1)
echo -e "\n - Servidors de Correu del domini"
i=1
if [ "$mail" == "" ]; then
	echo -e "\tNo hi ha servidors de correu disponibles per a $1"
fi
for name in $mail; do
	if [ $(($i%2)) == 0 ]; then
	nom=$(echo $name | cut -d' ' -f2)
	ip4=$(dig +short @$DNS -t A $nom)
	ip6=$(dig +short @$DNS -t AAAA $name)
	echo -e "\t$nom\t-->\tipv4: $ip4\tipv6: $ip6"
	fi
	i=$((i+1))
done

#extra
#servidors web
echo -e "\n - Servidors web del domini"
web=$(dig +short @$DNS -t A www.$1)
if [ "$web" != "" ]; then
	for ip in $web; do
		echo -e "\twww.$1\t--> $ip"
	done
else
	echo -e "\tNo no hi ha servidor web www.$1"
fi

#servidors ftp
echo -e "\n - Servidors web del domini"
ftp=$(dig +short @$DNS -t A ftp.$1)
if [ "$ftp" != "" ]; then
	for ip in $ftp; do
		echo -e "\tftp.$1\t--> $ip"
	done
else
	echo -e "\tNo no hi ha servidor ftp ftp.$1"
fi