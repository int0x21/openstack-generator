#!/bin/bash

source hosts.conf
declare -a hosts
declare -a loadbalancers

for var_name in ${!HOSTNAME_*}; do
	ip_var_name="HOSTIP${var_name#HOSTNAME}"
	host_entry="${!var_name}=${!ip_var_name}"
	hosts+=("$host_entry")
done
loadbalancers+=("${LOADBALANCER_HOST}=${LOADBALANCER_IP}")

password_file="passwords.conf"
password=$(grep 'HAPROXY_PASSWORD' "$password_file" | cut -d'=' -f2)


# Create base file
for host_info in "${hosts[@]}"; do
	hostname="${host_info%%=*}"
	cp ./sources/haproxy.cfg ./$hostname/
	cp ./sources/dataplaneapi.yml ./$hostname/
	chr=./$hostname/varhaproxy
	mkdir -p $chr/{bin,lib,lib64,usr/bin,tmp,script}
	list="$(ldd /usr/bin/awk | egrep -o '/lib.*\.[0-9]+')"
	for i in $list; do cp -v --parents "$i" "${chr}"; done
	cp -v /usr/bin/awk $chr/bin
	list="$(ldd /usr/bin/awk | egrep -o '/lib.*\.[0-9]+')"
	for i in $list; do cp -v --parents "$i" "${chr}"; done
	cp -v /usr/bin/rm $chr/bin
	list="$(ldd /usr/bin/awk | egrep -o '/lib.*\.[0-9]+')"
	for i in $list; do cp -v --parents "$i" "${chr}"; done
	cp -v /usr/bin/cat $chr/bin
	list="$(ldd /usr/bin/awk | egrep -o '/lib.*\.[0-9]+')"
	for i in $list; do cp -v --parents "$i" "${chr}"; done
	cp -v /bin/bash $chr/bin
	list="$(ldd /usr/bin/sed | egrep -o '/lib.*\.[0-9]+')"
	for i in $list; do cp -v --parents "$i" "${chr}"; done
	cp -v /bin/sed $chr/bin
	list="$(ldd /usr/bin/mysql | egrep -o '/lib.*\.[0-9]+')"
	for i in $list; do cp -v --parents "$i" "${chr}"; done
	cp -v /usr/bin/mysql $chr/usr/bin
	cp ./sources/galera-check.sh ./$hostname/varhaproxy/script/
done

# Set peer ip
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	lbip="${loadbalancers#*=}"
	lbhost="${loadbalancers%%=*}"
	sed -i "s/HOSTIP/$ip/" "./$hostname/haproxy.cfg"
	sed -i "s/LBIP/$lbip/" "./$hostname/haproxy.cfg"
	sed -i "s/LBHOST/$lbhost/" "./$hostname/haproxy.cfg"
	sed -i "s/HAPROXY_PASSWORD/$password/" "./$hostname/haproxy.cfg"
	sed -i "s/HOSTNAME/$hostname/" "./$hostname/dataplaneapi.yml"
done


