#!/bin/bash

source hosts.conf
declare -a hosts

for var_name in ${!HOSTNAME_*}; do
        ip_var_name="HOSTIP${var_name#HOSTNAME}"
        host_entry="${!var_name}=${!ip_var_name}"
        hosts+=("$host_entry")
done

password_file="passwords.conf"
password=$(grep 'HAPROXY_PASSWORD' "$password_file" | cut -d'=' -f2)

for host_info in "${hosts[@]}"; do
        ip="${host_info#*=}"
	hostname="${host_info%%=*}"
	if [[ "$ip" != "$myip" ]]; then
		scp -o "StrictHostKeyChecking no" ./$hostname/haproxy.cfg root@$hostname:/etc/haproxy/
		scp -r -o "StrictHostKeyChecking no" ./$hostname/varhaproxy/* root@$hostname:/var/lib/haproxy/
		scp -r -o "StrictHostKeyChecking no" ./$hostname/*.pem root@$hostname:/etc/haproxy/ssl/
		scp -o "StrictHostKeyChecking no" ./$hostname/lb-ca.pem root@$hostname:/usr/local/share/ca-certificates/lb-ca.crt
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'update-ca-certificates'";
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'chown haproxy:haproxy /var/lib/haproxy -R'";
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'chmod +x /var/lib/haproxy/script/galera-check.sh'";
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'wget https://github.com/haproxytech/dataplaneapi/releases/download/v2.9.2/dataplaneapi_2.9.2_linux_amd64.deb -O /tmp/dataplane.deb'";
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'dpkg -i /tmp/dataplane.deb'";
		scp -o "StrictHostKeyChecking no" ./$hostname/dataplaneapi.yml root@$hostname:/etc/dataplaneapi/
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'systemctl restart haproxy'";
		ssh -o "StrictHostKeyChecking no" root@$hostname "sudo bash -c 'systemctl restart dataplaneapi'";
	fi
done

