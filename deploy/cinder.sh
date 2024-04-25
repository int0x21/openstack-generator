#!/bin/bash

source hosts.conf
declare -a hosts
declare -a loadbalancers

password_file="passwords.conf"
cinderpassword=$(grep 'CINDER_PASSWORD' "$password_file" | cut -d'=' -f2)
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
		scp -o "StrictHostKeyChecking no" ./$hostname/cinder.conf root@$hostname:/etc/cinder/
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'ceph auth get-key client.cinder | tee client.cinder.key'"
                scp -o "StrictHostKeyChecking no" ./sources/secret.xml root@$hostname
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'virsh secret-define --file secret.xml'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'virsh secret-set-value --secret 725f0095-7663-4b22-b63d-647fb1e73f89 --base64 $(cat client.cinder.key) && rm client.cinder.key secret.xml'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-api'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart cinder-scheduler'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart cinder-volume'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart cinder-backup'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart apache2'"

	else
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 user create --domain default --password $cinderpassword cinder"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 role add --project service --user cinder admin"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 service create --name cinderv3 --description OpenStack-Block-Storage volumev3"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne volumev3 public https://$lb:8776/v3/%\(project_id\)s"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne volumev3 internal https://$lb:8776/v3/%\(project_id\)s"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne volumev3 admin https://$lb:8776/v3/%\(project_id\)s"
		scp -o "StrictHostKeyChecking no" ./$hostname/cinder.conf root@$hostname:/etc/cinder/
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'ceph auth get-key client.cinder | tee client.cinder.key'"
		scp -o "StrictHostKeyChecking no" ./sources/secret.xml root@$hostname
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'virsh secret-define --file secret.xml'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'virsh secret-set-value --secret 725f0095-7663-4b22-b63d-647fb1e73f89 --base64 $(cat client.cinder.key) && rm client.cinder.key secret.xml'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" 'su -s /bin/sh -c "cinder-manage db sync" cinder'
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-api'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart cinder-scheduler'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart cinder-volume'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart cinder-backup'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart apache2'"
	fi
done
