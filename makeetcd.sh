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

# Create base file
for host_info in "${hosts[@]}"; do
	hostname="${host_info%%=*}"
	cp ./sources/etcd ./$hostname/
done

# Set peer ip
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	sed -i "s/HOSTIP/$ip/" "./$hostname/etcd"
	sed -i "s/HOSTNAME/$hostname/" "./$hostname/etcd"
done

modified_hosts=()
for host in "${hosts[@]}"; do
    # Split the host and IP based on '=' character
    IFS='=' read -r hostname ip <<< "$host"

    # Append 'http://', port ':2380' to the IP, and format it as required
    modified_hosts+=("${hostname}=http://${ip}:2380")
done

for host_info in "${hosts[@]}"; do
	ip="${host_info#*=}"
	hostname="${host_info%%=*}"
	string=$(IFS=,; echo "${modified_hosts[*]}")
	sed -i "s@CLUSTERSTRING@$string@" "./$hostname/etcd"
done
