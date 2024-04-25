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
	scp -o "StrictHostKeyChecking no" ./$hostname/apache_keystone.conf root@$hostname:/etc/apache2/sites-enabled/keystone.conf
	scp -o "StrictHostKeyChecking no" ./$hostname/keystone.conf root@$hostname:/etc/keystone/
	scp -o "StrictHostKeyChecking no" ./$hostname/placement.conf root@$hostname:/etc/placement/
	scp -o "StrictHostKeyChecking no" ./$hostname/placement-api.conf root@$hostname:/etc/apache2/sites-enabled/placement-api.conf
	scp -o "StrictHostKeyChecking no" ./$hostname/cinder-wsgi.conf root@$hostname:/etc/apache2/conf-enabled/
	ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart apache2'"
done
