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
password=$(grep 'CINDER_PASSWORD' "$password_file" | cut -d'=' -f2)

# Create base file
for host_info in "${hosts[@]}"; do
	hostname="${host_info%%=*}"
	cp ./sources/cinder.conf ./$hostname/
done

# Set peer ip
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	lbhost="${loadbalancers%%=*}"
	sed -i "s/HOSTIP/$ip/" "./$hostname/cinder.conf"
	sed -i "s/LBHOST/$lbhost/" "./$hostname/cinder.conf"
	sed -i "s/CINDERPASSWORD/$password/" "./$hostname/cinder.conf"
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
	sed -i "s@MEMCACHEDSTRING@$string@" "./$hostname/cinder.conf"
done

password=$(grep 'OPENSTACK_PASSWORD' "$password_file" | cut -d'=' -f2)
modified_hosts=()
for host in "${hosts[@]%%=*}"; do
    # Split the host and IP based on '=' character
    IFS=',' read -r hostname <<< "$host"

    modified_hosts+=("openstack:$password@${hostname}:5672")
done

for host_info in "${hosts[@]}"; do
        ip="${host_info#*=}"
        hostname="${host_info%%=*}"
        string=$(IFS=,; echo "${modified_hosts[*]}")
        sed -i "s#TRANSPORTSTRING#$string#" "./$hostname/cinder.conf"
done


