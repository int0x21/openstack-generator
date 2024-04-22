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
password=$(grep 'PLACEMENT_PASSWORD' "$password_file" | cut -d'=' -f2)

# Create base file
for host_info in "${hosts[@]}"; do
	hostname="${host_info%%=*}"
	cp ./sources/placement.conf ./$hostname/
done

# Set peer ip
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	lbhost="${loadbalancers%%=*}"
	sed -i "s/LBHOST/$lbhost/" "./$hostname/placement.conf"
	sed -i "s/PLACEMENTPASSWORD/$password/" "./$hostname/placement.conf"
done

modified_hosts=()
for host in "${hosts[@]%%=*}"; do
    # Split the host and IP based on '=' character
    IFS=',' read -r hostname <<< "$host"

    modified_hosts+=("${hostname}:11211")
done


for host_info in "${hosts[@]}"; do
	ip="${host_info#*=}"
	hostname="${host_info%%=*}"
	string=$(IFS=,; echo "${modified_hosts[*]}")
	sed -i "s@MEMCACHEDSTRING@$string@" "./$hostname/placement.conf"
done


