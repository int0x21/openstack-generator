#!/bin/bash

source hosts.conf
declare -a hosts
declare -a loadbalancers

password_file="passwords.conf"
neutronpassword=$(grep 'NEUTRON_PASSWORD' "$password_file" | cut -d'=' -f2)
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
		scp -o "StrictHostKeyChecking no" ./$hostname/neutron.conf root@$hostname:/etc/neutron/
                scp -o "StrictHostKeyChecking no" ./$hostname/ml2_conf.ini root@$hostname:/etc/neutron/plugins/ml2/
                scp -o "StrictHostKeyChecking no" ./$hostname/openvswitch_agent.ini root@$hostname:/etc/neutron/plugins/ml2
                scp -o "StrictHostKeyChecking no" ./$hostname/dhcp_agent.ini root@$hostname:/etc/neutron/
                scp -o "StrictHostKeyChecking no" ./$hostname/metadata_agent.ini root@$hostname:/etc/neutron/
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-api'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart neutron-server'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart neutron-openvswitch-agent'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart neutron-dhcp-agent'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart neutron-metadata-agent'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart neutron-l3-agent'"
                ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-compute'"
	else
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 user create --domain default --password $neutronpassword neutron"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 role add --project service --user neutron admin"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 service create --name neutron --description OpenStack-Networking network"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne network public https://$lb:9696"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne network internal https://$lb:9696"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "openstack --os-username admin --os-password $keystonepassword --os-project-name admin --os-user-domain-name Default --os-project-domain-name Default --os-auth-url https://$lb:5000/v3 --os-identity-api-version 3 --os-image-api-version 2 endpoint create --region RegionOne network admin https://$lb:9696"
		scp -o "StrictHostKeyChecking no" ./$hostname/neutron.conf root@$hostname:/etc/neutron/
		scp -o "StrictHostKeyChecking no" ./$hostname/ml2_conf.ini root@$hostname:/etc/neutron/plugins/ml2/
		scp -o "StrictHostKeyChecking no" ./$hostname/openvswitch_agent.ini root@$hostname:/etc/neutron/plugins/ml2
		scp -o "StrictHostKeyChecking no" ./$hostname/dhcp_agent.ini root@$hostname:/etc/neutron/
		scp -o "StrictHostKeyChecking no" ./$hostname/metadata_agent.ini root@$hostname:/etc/neutron/
		ssh -o "StrictHostKeyChecking no" "root@$ip" 'su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron'
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-api'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart neutron-server'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart neutron-openvswitch-agent'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart neutron-dhcp-agent'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart neutron-metadata-agent'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart neutron-l3-agent'"
		ssh -o "StrictHostKeyChecking no" "root@$ip" "bash -c 'systemctl restart nova-compute'"
	fi
done
