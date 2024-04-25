#!/bin/bash

source hosts.conf
declare -a hosts
declare -a loadbalancers

password_file="passwords.conf"
placementpassword=$(grep 'PLACEMENT_PASSWORD' "$password_file" | cut -d'=' -f2)
keystonepassword=$(grep 'KEYSTONE_PASSWORD' "$password_file" | cut -d'=' -f2)

for var_name in ${!HOSTNAME_*}; do
        ip_var_name="HOSTIP${var_name#HOSTNAME}"
        host_entry="${!var_name}=${!ip_var_name}"
        hosts+=("$host_entry")
done
loadbalancers+=("${LOADBALANCER_HOST}=${LOADBALANCER_IP}")

for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
        lb="${loadbalancers%%=*}"
        myip="${hosts[0]#*=}"
        myhost="${hosts[0]%%=*}"
        if [[ "$ip" != "$myip" ]]; then
                echo $hostname
		scp -o "StrictHostKeyChecking no" ./$hostname/placement.conf root@$hostname:/etc/placement/
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart apache2'"
	else
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 user create --domain default --password $placementpassword placement"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 role add --project service --user placement admin"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 service create --name placement --description Placement-API placement"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne placement public https://$lb:8778"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne placement internal https://$lb:8778"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne placement admin https://$lb:8778"
		scp -o "StrictHostKeyChecking no" ./$hostname/placement.conf root@$hostname:/etc/placement/
		ssh -o "StrictHostKeyChecking no" "root@$ip" 'su -s /bin/sh -c "placement-manage db sync" placement'
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart apache2'"
	fi
done
