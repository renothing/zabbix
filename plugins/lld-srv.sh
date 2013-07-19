#!/bin/bash
key=$@
[[ -z $key ]] && key=nginx
key=`echo $key|sed 's/[[:space:]]/\|/g;s/^/(/;s/$/)/;'`
ports=($(netstat -antp|egrep "^tcp[^1-9].*LISTEN"|awk '$NF ~ /'"$key"'/ || $(NF-1) ~ /'"$key"'/ {print $4}'|cut -d':' -f2))
names=($(netstat -antp|egrep "^tcp[^1-9].*LISTEN"|awk '$NF ~ /'"$key"'/ || $(NF-1) ~ /'"$key"'/ {print $7}'|cut -d'/' -f2))
printf '{\n'
printf '\t"data":[\n'
	for k in ${!ports[@]};do
		if [[ "${#ports[@]}" -gt 1 && "${k}" -ne "$((${#ports[@]}-1))" ]];then
			printf '\t\t{\n'
			printf "\t\t\t\"{#KNAME}\":\"${names[${k}]}\",\n"
			printf "\t\t\t\"{#KPORT}\":\"${ports[${k}]}\""
			printf '\t},\n'
		else [[ "${k}" -eq "((${#ports[@]}-1))" ]]
			printf '\t\t{\n'
			printf "\t\t\t\"{#KNAME}\":\"${names[${k}]}\",\n"
			printf "\t\t\t\"{#KPORT}\":\"${ports[${k}]}\""
			printf '\t}\n'
		fi
	done
printf '\t ]\n'
printf '}\n'
