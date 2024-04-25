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
password=$(grep 'KEYSTONE_PASSWORD' "$password_file" | cut -d'=' -f2)

# Create base file
cp ./sources/admin-openrc ./

lbhost="${loadbalancers%%=*}"
sed -i "s/LBHOST/$lbhost/" "./admin-openrc"
sed -i "s/KEYSTONE_PASSWORD/$password/" "./admin-openrc"
