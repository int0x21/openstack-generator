#!/bin/bash

source hosts.conf
declare -a hosts
declare -a loadbalancers

password_file="passwords.conf"
password=$(grep 'KEYSTONE_PASSWORD' "$password_file" | cut -d'=' -f2)

for var_name in ${!HOSTNAME_*}; do
        ip_var_name="HOSTIP${var_name#HOSTNAME}"
        host_entry="${!var_name}=${!ip_var_name}"
        hosts+=("$host_entry")
done
loadbalancers+=("${LOADBALANCER_HOST}=${LOADBALANCER_IP}")

if echo 'keystone-fernet' | sudo ceph fs volume ls | grep -q 'keystone-fernet'; then
	echo "fernet volume already exists"
else
	sudo ceph fs volume create keystone-fernet
fi


# populate fstab
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	if ssh -o "StrictHostKeyChecking no" "root@$ip" "echo 'keystone-fernet' | grep -q 'keystone-fernet' /etc/fstab"; then
		echo "keystone-fernet already in fstab"
        else
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'echo "admin@.keystone-fernet=/    /etc/keystone/fernet-keys    ceph    rw,noatime,_netdev    0      0" >> /etc/fstab'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'mount /etc/keystone/fernet-keys'"
        fi
done

for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
        lb="${loadbalancers%%=*}"
        myip="${hosts[0]#*=}"
        myhost="${hosts[0]%%=*}"
	echo "copy apache_kestone.conf"
	echo "copy keystone.conf"
	if ssh -o "StrictHostKeyChecking no" "root@$ip" "echo '$lb' | grep -q '$lb' /etc/apache2/apache2.conf"; then
                echo "$lb already in apache2.conf"
        else
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'echo "ServerName $lb" >> /etc/apache2/apache2.conf'"
        fi
	ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart apache2'"

        if [[ "$ip" != "$myip" ]]; then
                echo $hostname
        	ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart apache2'"
	else
                echo $hostname
		echo "1"
		ssh -o "StrictHostKeyChecking no" "root@$ip" 'chown keystone:keystone /etc/keystone/fernet-keys -R'
		ssh -o "StrictHostKeyChecking no" "root@$ip" 'su -s /bin/sh -c "keystone-manage db_sync" keystone'
		echo "2"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'keystone-manage credential_setup --keystone-user keystone --keystone-group keyston'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'keystone-manage bootstrap --bootstrap-password $password --bootstrap-admin-url https://$lb:5000/v3/ --bootstrap-internal-url https://$lb:5000/v3/ --bootstrap-public-url https://$lb:5000/v3/ --bootstrap-region-id RegionOne'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart apache2'"
	fi
done
