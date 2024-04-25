#!/bin/bash

source hosts.conf
declare -a hosts
declare -a loadbalancers

password_file="passwords.conf"
novapassword=$(grep 'NOVA_PASSWORD' "$password_file" | cut -d'=' -f2)
keystonepassword=$(grep 'KEYSTONE_PASSWORD' "$password_file" | cut -d'=' -f2)

for var_name in ${!HOSTNAME_*}; do
        ip_var_name="HOSTIP${var_name#HOSTNAME}"
        host_entry="${!var_name}=${!ip_var_name}"
        hosts+=("$host_entry")
done
loadbalancers+=("${LOADBALANCER_HOST}=${LOADBALANCER_IP}")

if echo 'volumes' | sudo ceph osd pool ls | grep -q 'volumes'; then
	echo "volumes pool already exists"
else
	sudo ceph osd pool create volumes
	sudo rbd pool init volumes
fi
if echo 'backups' | sudo ceph osd pool ls | grep -q 'backups'; then
        echo "backups pool already exists"
else
        sudo ceph osd pool create backups
        sudo rbd pool init backups
fi
if echo 'vms' | sudo ceph osd pool ls | grep -q 'vms'; then
        echo "vms pool already exists"
else
        sudo ceph osd pool create vms
        sudo rbd pool init vms
fi
sudo ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'
sudo ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'
sudo ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'

for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
        lb="${loadbalancers%%=*}"
        myip="${hosts[0]#*=}"
        myhost="${hosts[0]%%=*}"
        if [[ "$ip" != "$myip" ]]; then
                echo $hostname
		scp -o "StrictHostKeyChecking no" ./$hostname/nova.conf root@$hostname:/etc/nova/
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'ceph auth get-or-create client.cinder | tee /etc/ceph/ceph.client.cinder.keyring'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'ceph auth get-or-create client.cinder-backup | tee /etc/ceph/ceph.client.cinder-backup.keyring'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-api'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-scheduler'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-conductor'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-novncproxy'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-compute'"
	else
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 user create --domain default --password $novapassword nova"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 role add --project service --user nova admin"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 service create --name nova --description OpenStack-Compute compute"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne compute public https://$lb:8774/v2.1"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne compute internal https://$lb:8774/v2.1"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne compute admin https://$lb:8774/v2.1"
		scp -o "StrictHostKeyChecking no" ./$hostname/nova.conf root@$hostname:/etc/nova/
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'ceph auth get-or-create client.cinder | tee /etc/ceph/ceph.client.cinder.keyring'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'ceph auth get-or-create client.cinder-backup | tee /etc/ceph/ceph.client.cinder-backup.keyring'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" 'su -s /bin/sh -c "nova-manage api_db sync" nova'
		ssh -o "StrictHostKeyChecking no" "root@$ip" 'su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova'
		ssh -o "StrictHostKeyChecking no" "root@$ip" 'su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova'
		ssh -o "StrictHostKeyChecking no" "root@$ip" 'su -s /bin/sh -c "nova-manage db sync" nova'
		ssh -o "StrictHostKeyChecking no" "root@$ip" 'su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova'
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-api'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-scheduler'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-conductor'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-novncproxy'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-compute'"
	fi
done
sudo su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
