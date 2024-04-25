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
        for peer_ip in "${hosts[@]}"; do
                pip="${peer_ip#*=}"
                phostname="${peer_ip%%=*}"
                CFGVER=$(curl -s -u admin:$password http://$ip:5555/v2/services/haproxy/configuration/version)
                curl -u admin:$password -X POST "http://$ip:5555/v2/services/haproxy/configuration/servers?backend=galera_backend&version=$CFGVER" -H "Content-Type: application/json" -d '{ "check": "enabled", "fall": 5, "inter": 10000, "rise": 2, "address": "'$pip'", "name": "'$phostname'", "port": 3306 }'
        done
	for peer_ip in "${hosts[@]}"; do
                pip="${peer_ip#*=}"
                phostname="${peer_ip%%=*}"
                CFGVER=$(curl -s -u admin:$password http://$ip:5555/v2/services/haproxy/configuration/version)
                curl -u admin:$password -X POST "http://$ip:5555/v2/services/haproxy/configuration/servers?backend=cinder_api_backend&version=$CFGVER" -H "Content-Type: application/json" -d '{ "check": "enabled", "fall": 5, "inter": 10000, "rise": 2, "address": "'$pip'", "name": "'$phostname'", "port": 8776 }'
        done
	for peer_ip in "${hosts[@]}"; do
                pip="${peer_ip#*=}"
                phostname="${peer_ip%%=*}"
                CFGVER=$(curl -s -u admin:$password http://$ip:5555/v2/services/haproxy/configuration/version)
                curl -u admin:$password -X POST "http://$ip:5555/v2/services/haproxy/configuration/servers?backend=nova_metadata_api_backend&version=$CFGVER" -H "Content-Type: application/json" -d '{ "check": "enabled", "fall": 5, "inter": 10000, "rise": 2, "address": "'$pip'", "name": "'$phostname'", "port": 8775 }'
        done
	for peer_ip in "${hosts[@]}"; do
                pip="${peer_ip#*=}"
                phostname="${peer_ip%%=*}"
                CFGVER=$(curl -s -u admin:$password http://$ip:5555/v2/services/haproxy/configuration/version)
                curl -u admin:$password -X POST "http://$ip:5555/v2/services/haproxy/configuration/servers?backend=neutron_api_backend&version=$CFGVER" -H "Content-Type: application/json" -d '{ "check": "enabled", "fall": 5, "inter": 10000, "rise": 2, "address": "'$pip'", "name": "'$phostname'", "port": 9696 }'
        done
	for peer_ip in "${hosts[@]}"; do
                pip="${peer_ip#*=}"
                phostname="${peer_ip%%=*}"
                CFGVER=$(curl -s -u admin:$password http://$ip:5555/v2/services/haproxy/configuration/version)
                curl -u admin:$password -X POST "http://$ip:5555/v2/services/haproxy/configuration/servers?backend=nova_vncproxy_backend&version=$CFGVER" -H "Content-Type: application/json" -d '{ "check": "enabled", "fall": 5, "inter": 10000, "rise": 2, "address": "'$pip'", "name": "'$phostname'", "port": 6080 }'
        done
	for peer_ip in "${hosts[@]}"; do
                pip="${peer_ip#*=}"
                phostname="${peer_ip%%=*}"
                CFGVER=$(curl -s -u admin:$password http://$ip:5555/v2/services/haproxy/configuration/version)
                curl -u admin:$password -X POST "http://$ip:5555/v2/services/haproxy/configuration/servers?backend=nova_compute_api_backend&version=$CFGVER" -H "Content-Type: application/json" -d '{ "check": "enabled", "fall": 5, "inter": 10000, "rise": 2, "address": "'$pip'", "name": "'$phostname'", "port": 8774 }'
        done
	for peer_ip in "${hosts[@]}"; do
                pip="${peer_ip#*=}"
                phostname="${peer_ip%%=*}"
                CFGVER=$(curl -s -u admin:$password http://$ip:5555/v2/services/haproxy/configuration/version)
                curl -u admin:$password -X POST "http://$ip:5555/v2/services/haproxy/configuration/servers?backend=placement_backend&version=$CFGVER" -H "Content-Type: application/json" -d '{ "check": "enabled", "fall": 5, "inter": 10000, "rise": 2, "address": "'$pip'", "name": "'$phostname'", "port": 8778 }'
        done
	for peer_ip in "${hosts[@]}"; do
                pip="${peer_ip#*=}"
                phostname="${peer_ip%%=*}"
                CFGVER=$(curl -s -u admin:$password http://$ip:5555/v2/services/haproxy/configuration/version)
                curl -u admin:$password -X POST "http://$ip:5555/v2/services/haproxy/configuration/servers?backend=glance_api_backend&version=$CFGVER" -H "Content-Type: application/json" -d '{ "check": "enabled", "fall": 5, "inter": 10000, "rise": 2, "address": "'$pip'", "name": "'$phostname'", "port": 9292 }'
        done
	for peer_ip in "${hosts[@]}"; do
                pip="${peer_ip#*=}"
                phostname="${peer_ip%%=*}"
                CFGVER=$(curl -s -u admin:$password http://$ip:5555/v2/services/haproxy/configuration/version)
                curl -u admin:$password -X POST "http://$ip:5555/v2/services/haproxy/configuration/servers?backend=keystone_backend&version=$CFGVER" -H "Content-Type: application/json" -d '{ "check": "enabled", "fall": 5, "inter": 10000, "rise": 2, "address": "'$pip'", "name": "'$phostname'", "port": 5000 }'
        done
done

