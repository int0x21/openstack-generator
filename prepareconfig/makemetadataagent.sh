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
password=$(grep 'NEUTRON_PASSWORD' "$password_file" | cut -d'=' -f2)

# Create base file
for host_info in "${hosts[@]}"; do
	hostname="${host_info%%=*}"
	cp ./sources/metadata_agent.ini ./$hostname/
done

# Set peer ip
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	lbhost="${loadbalancers%%=*}"
	sed -i "s/LBHOST/$lbhost/" "./$hostname/metadata_agent.ini"
	sed -i "s/NEUTRONPASSWORD/$password/" "./$hostname/metadata_agent.ini"
done
