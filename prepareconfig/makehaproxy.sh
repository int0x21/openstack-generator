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
done

# Set peer ip
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	lbip="${loadbalancers#*=}"
	sed -i "s/HOSTIP/$ip/" "./$hostname/haproxy.cfg"
	sed -i "s/LBIP/$lbip/" "./$hostname/haproxy.cfg"
	sed -i "s/HAPROXY_PASSWORD/$password/" "./$hostname/haproxy.cfg"
done
