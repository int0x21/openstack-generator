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
	ssh -o "StrictHostKeyChecking no" $ip "sudo bash -c 'ovs-vsctl add-br br-infra'"
	ssh -o "StrictHostKeyChecking no" $ip "sudo bash -c 'ovs-vsctl add-port br-infra mgmt tag=3005 -- set interface mgmt type=internal'"
	ssh -o "StrictHostKeyChecking no" $ip "sudo bash -c 'ovs-vsctl add-port br-infra storage tag=3004 -- set interface storage type=internal'"
	ssh -o "StrictHostKeyChecking no" $ip "sudo bash -c 'ovs-vsctl add-port br-infra vxlan tag=3006 -- set interface vxlan type=internal'"
	ssh -o "StrictHostKeyChecking no" $ip "sudo bash -c 'ovs-vsctl add-port br-infra bond0'"
	ssh -o "StrictHostKeyChecking no" $ip "sudo bash -c 'systemctl restart openvswitch-switch'"
done

