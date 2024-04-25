#!/bin/bash

source hosts.conf
declare -a hosts
declare -a loadbalancers

password_file="passwords.conf"
glancepassword=$(grep 'GLANCE_PASSWORD' "$password_file" | cut -d'=' -f2)
keystonepassword=$(grep 'KEYSTONE_PASSWORD' "$password_file" | cut -d'=' -f2)

for var_name in ${!HOSTNAME_*}; do
        ip_var_name="HOSTIP${var_name#HOSTNAME}"
        host_entry="${!var_name}=${!ip_var_name}"
        hosts+=("$host_entry")
done
loadbalancers+=("${LOADBALANCER_HOST}=${LOADBALANCER_IP}")

if echo 'images' | sudo ceph osd pool ls | grep -q 'images'; then
	echo "images pool already exists"
else
	sudo ceph osd pool create images
	sudo rbd pool init images
	sudo ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'
fi

for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
        lb="${loadbalancers%%=*}"
        myip="${hosts[0]#*=}"
        myhost="${hosts[0]%%=*}"
        if [[ "$ip" != "$myip" ]]; then
                echo $hostname
		scp -o "StrictHostKeyChecking no" ./$hostname/glance-api.conf root@$hostname:/etc/glance/
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'ceph auth get-or-create client.glance | tee /etc/ceph/ceph.client.glance.keyring'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart glance-api'"
	else
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 user create --domain default --password $glancepassword glance"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 project create --domain default --description Service-Project service"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 role add --project service --user glance admin"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 service create --name glance --description OpenStack-Image image"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne image public https://$lb:9292"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne image internal https://$lb:9292"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne image admin https://$lb:9292"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 role add --user glance --user-domain Default --system all reader"
		scp -o "StrictHostKeyChecking no" ./$hostname/glance-api.conf root@$hostname:/etc/glance/
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'ceph auth get-or-create client.glance | tee /etc/ceph/ceph.client.glance.keyring'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" 'su -s /bin/sh -c "glance-manage db_sync" glance'
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart glance-api'"
	fi
done
