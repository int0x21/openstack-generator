#!/bin/bash

PRIVKEY=sshkeys/id_rsa
PUBKEY=sshkeys/id_rsa.pub

chmod 600 $PRIVKEY
chmod 600 $PUBKEY

if [ -f "$PRIVKEY" ]; then
	cp $PRIVKEY ~/.ssh/id_rsa
	chmod 600 ~/.ssh/id_rsa
fi

if [ -f "$PUBKEY" ]; then
	cp $PUBKEY ~/.ssh/id_rsa.pub
	chmod 600 ~/.ssh/id_rsa.pub
fi

source hosts.conf
declare -a hosts
declare -a loadbalancers

for var_name in ${!HOSTNAME_*}; do
        ip_var_name="HOSTIP${var_name#HOSTNAME}"
        host_entry="${!var_name}=${!ip_var_name}"
        hosts+=("$host_entry")
done
loadbalancers+=("${LOADBALANCER_HOST}=${LOADBALANCER_IP}")

# populate hostfile
for host_info in "${hosts[@]}"; do
        hostname="${host_info%%=*}"
        ip="${host_info#*=}"
	if ssh -i "$PRIVKEY" -o "StrictHostKeyChecking no" "$ip" "echo '${loadbalancers#*=} ${loadbalancers%%=*}' | grep -q '${loadbalancers#*=} ${loadbalancers%%=*}' /etc/hosts"; then
		echo "Loadbalancer already in hosts"
        else
                ssh -i $PRIVKEY -o "StrictHostKeyChecking no" $ip "sudo bash -c 'echo "${loadbalancers#*=} ${loadbalancers%%=*}" >> /etc/hosts'"
        fi
	for peer_ip in "${hosts[@]}"; do
		pip="${peer_ip#*=}"
		phostname="${peer_ip%%=*}"
		if ssh -i "$PRIVKEY" -o "StrictHostKeyChecking no" "$ip" "echo '$pip $phostname' | grep -q '$pip $phostname' /etc/hosts"; then
			echo "$phostname already in hosts"
		else
			ssh -i $PRIVKEY -o "StrictHostKeyChecking no" $ip "sudo bash -c 'echo "$pip $phostname" >> /etc/hosts'"
		fi
	done
done

# add ssh keys

for host_info in "${hosts[@]}"; do
        ip="${host_info#*=}"
	scp -i $PRIVKEY -o "StrictHostKeyChecking no" $PRIVKEY "$ip:~/.ssh/"
	scp -i $PRIVKEY -o "StrictHostKeyChecking no" $PUBKEY "$ip:~/.ssh/"
done
