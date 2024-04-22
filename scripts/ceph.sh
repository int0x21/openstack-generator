#!/bin/bash

source hosts.conf
declare -a hosts
declare -a monip

password_file="passwords.conf"
password=$(grep 'CEPH_PASSWORD' "$password_file" | cut -d'=' -f2)

for var_name in ${!HOSTNAME_*}; do
        ip_var_name="HOSTIP${var_name#HOSTNAME}"
        host_entry="${!var_name}=${!ip_var_name}"
        hosts+=("$host_entry")
done
monip+=("${MON_HOST}=${MON_IP}")

sudo cephadm bootstrap --config cephbootstrap.conf --initial-dashboard-password $password --initial-dashboard-user admin --dashboard-password-noupdate --mon-ip ${monip#*=}

for host_info in "${hosts[@]}"; do
        ip="${host_info#*=}"
	hostname="${host_info%%=*}"
        myip="${hosts[0]#*=}"
	if [[ "$ip" != "$myip" ]]; then
		ssh-copy-id -o "StrictHostKeyChecking no" -f -i /etc/ceph/ceph.pub root@$hostname
		sudo ceph orch host add $hostname --labels _admin
	fi
done

sudo ceph orch apply osd --all-available-devices
