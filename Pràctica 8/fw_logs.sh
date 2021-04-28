#!/bin/bash

#fitxer sense consultar
logs="/var/log/iptables.log"
#historial de consultats
new="/var/log/iptables.history"

log=$(cat $logs | grep iptables)
full=$(echo -ne "$log" | wc -l)
i=1

#creem l'historial si no hi es
if [ ! -e $new ]; then
	touch /var/log/iptables.history
fi

#buidatge a l'historial
echo -ne "$log" >> $new
cat /dev/null > $logs

#tractament
while [ $i -lt $(( $full+1 )) ]; do
	line=$(echo -e "$log" | awk NR==$i | tr ' ' '\n')
	type=$(echo -e "$line" | grep type)
	addr=$(echo -e "$line" | grep SRC)
	mac=$(echo -e "$line" | grep MAC)
	#output
	echo -e "$i: $type from: $addr - $mac"

	i=$(( $i + 1 ))
done
