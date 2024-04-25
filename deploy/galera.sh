#!/bin/bash

source hosts.conf
declare -a hosts

for var_name in ${!HOSTNAME_*}; do
        ip_var_name="HOSTIP${var_name#HOSTNAME}"
        host_entry="${!var_name}=${!ip_var_name}"
        hosts+=("$host_entry")
done

for host_info in "${hosts[@]}"; do
        ip="${host_info#*=}"
	hostname="${host_info%%=*}"
	myip="${hosts[0]#*=}"
	if [[ "$ip" != "$myip" ]]; then
		echo $hostname
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'systemctl stop mariadb'";
		scp -o "StrictHostKeyChecking no" ./$hostname/50-server.cnf root@$hostname:/etc/mysql/mariadb.conf.d/
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'systemctl restart mariadb'";
	else
		echo $hostname
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'systemctl stop mariadb'";
		scp -o "StrictHostKeyChecking no" ./$hostname/50-server.cnf root@$hostname:/etc/mysql/mariadb.conf.d/
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'galera_new_cluster'";
	fi
done

