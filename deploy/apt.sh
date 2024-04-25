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
#	scp -o "StrictHostKeyChecking no" "sources/ceph-pin" "root@$ip:/etc/apt/preferences.d/"
	ssh -o "StrictHostKeyChecking no" "$ip" "bash -c 'curl --silent --remote-name --location https://download.ceph.com/rpm-18.2.2/el9/noarch/cephadm'";
	ssh -o "StrictHostKeyChecking no" "$ip" "bash -c 'chmod +x cephadm'";
	ssh -o "StrictHostKeyChecking no" "$ip" "sudo bash -c './cephadm add-repo --release reef'";
	ssh -o "StrictHostKeyChecking no" "$ip" "sudo bash -c 'add-apt-repository cloud-archive:caracal -y'";
	ssh -o "StrictHostKeyChecking no" "$ip" "sudo bash -c './cephadm install'";
	ssh -o "StrictHostKeyChecking no" "$ip" "sudo bash -c 'apt-get update -y'";
	ssh -o "StrictHostKeyChecking no" "$ip" "sudo bash -c 'apt-get upgrade -y'";
	ssh -o "StrictHostKeyChecking no" "$ip" "sudo bash -c 'apt-get install cinder-backup cinder-volume cinder-api cinder-scheduler mariadb-server haproxy keepalived python3-openstackclient rabbitmq-server erlang-ssl erlang-asn1 erlang-crypto erlang-public-key memcached python3-memcache golang-cfssl etcd keystone glance placement-api python3-pip nova-api nova-conductor nova-novncproxy nova-scheduler nova-compute neutron-server neutron-plugin-ml2 neutron-openvswitch-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent ceph-base cephadm ceph-common qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst libvirt-daemon-driver-storage-rbd -y'";
done
