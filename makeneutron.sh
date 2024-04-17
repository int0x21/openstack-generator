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
	cp ./sources/neutron.conf ./$hostname/
done

# Set peer ip
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	lbhost="${loadbalancers%%=*}"
	sed -i "s/HOSTIP/$ip/" "./$hostname/neutron.conf"
	sed -i "s/LBHOST/$lbhost/" "./$hostname/neutron.conf"
	sed -i "s/NEUTRONPASSWORD/$password/" "./$hostname/neutron.conf"
done

password=$(grep 'PLACEMENT_PASSWORD' "$password_file" | cut -d'=' -f2)
for host_info in "${hosts[@]}"; do
	hostname="${host_info%%=*}"
	sed -i "s/PLACEMENTPASSWORD/$password/" "./$hostname/neutron.conf"
done

password=$(grep 'NOVA_PASSWORD' "$password_file" | cut -d'=' -f2)
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        sed -i "s/NOVAPASSWORD/$password/" "./$hostname/neutron.conf"
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
	sed -i "s@MEMCACHEDSTRING@$string@" "./$hostname/neutron.conf"
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
        sed -i "s#TRANSPORTSTRING#$string#" "./$hostname/neutron.conf"
done


