#!/bin/bash

source hosts.conf
declare -a hosts

password_file="passwords.conf"
passwordrabbit=$(grep 'RABBITMQ_PASSWORD' "$password_file" | cut -d'=' -f2)
passwordopenstack=$(grep 'OPENSTACK_PASSWORD' "$password_file" | cut -d'=' -f2)

for var_name in ${!HOSTNAME_*}; do
        ip_var_name="HOSTIP${var_name#HOSTNAME}"
        host_entry="${!var_name}=${!ip_var_name}"
        hosts+=("$host_entry")
done

for host_info in "${hosts[@]}"; do
        ip="${host_info#*=}"
	hostname="${host_info%%=*}"
	myip="${hosts[0]#*=}"
	myhost="${hosts[0]%%=*}"
	if [[ "$ip" != "$myip" ]]; then
		echo $hostname
#		scp -o "StrictHostKeyChecking no" ./$hostname/rabbitmq.conf root@$hostname:/etc/rabbitmq/
#		scp -o "StrictHostKeyChecking no" ./$hostname/rabbitmq-env.conf root@$hostname:/etc/rabbitmq/
		ssh -o "StrictHostKeyChecking no" root@$hostname "rabbitmq-plugins enable rabbitmq_management"
		ssh -o "StrictHostKeyChecking no" root@$hostname "systemctl restart rabbitmq-server"
		ssh -o "StrictHostKeyChecking no" root@$hostname "rabbitmqctl stop_app"
		ssh -o "StrictHostKeyChecking no" root@$hostname "rabbitmqctl join_cluster rabbit@$myhost"
		ssh -o "StrictHostKeyChecking no" root@$hostname "rabbitmqctl start_app"
	else
		echo $hostname
#		scp -o "StrictHostKeyChecking no" ./$hostname/rabbitmq.conf root@$hostname:/etc/rabbitmq/
#		scp -o "StrictHostKeyChecking no" ./$hostname/rabbitmq-env.conf root@$hostname:/etc/rabbitmq/
		ssh -o "StrictHostKeyChecking no" root@$hostname "rabbitmq-plugins enable rabbitmq_management"
		ssh -o "StrictHostKeyChecking no" root@$hostname "systemctl restart rabbitmq-server"
		for peer_info in "${hosts[@]}"; do
			pip="${peer_info#*=}"
			phostname="${peer_info%%=*}"
			if [[ "$pip" != "$myip" ]]; then
				echo "$myip to $pip"
				sudo scp -o "StrictHostKeyChecking no" /var/lib/rabbitmq/.erlang.cookie root@$pip:/var/lib/rabbitmq/
			fi
		done

	fi
done

sudo rabbitmqctl add_user admin $passwordrabbit
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
sudo rabbitmqctl delete_user guest
sudo rabbitmqctl set_policy ha-all ".*" '{"ha-mode":"all"}'
sudo rabbitmqctl add_user openstack $passwordopenstack
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

