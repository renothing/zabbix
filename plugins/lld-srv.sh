#!/bin/bash
key=$1
[[ -z $key ]] && key=nginx
ports=($(netstat -antp|egrep "^tcp[^1-9].*LISTEN"|awk '$NF ~ /'"$key"'/ || $(NF-1) ~ /'"$key"'/ {print $4}'|cut -d':' -f2))
printf '{\n'
printf '\t"data":[\n'
        for k in ${!ports[@]};do
                if [[ "${#ports[@]}" -gt 1 && "${k}" -ne "$((${#ports[@]}-1))" ]];then
                        printf '\t\t{\n'
                        printf "\t\t\t\"{#$key}\":\"${ports[${k}]}\""
                        printf '\t},\n'
                else [[ "${k}" -eq "((${#ports[@]}-1))" ]]
                        printf '\t\t{\n'
                        printf "\t\t\t\"{#$key}\":\"${ports[${k}]}\""
                        printf '\t}\n'
                fi
        done
printf '\t ]\n'
printf '}\n'
