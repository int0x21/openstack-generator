#!/bin/bash

source hosts.conf
declare -a hosts
declare -a loadbalancers

for var_name in ${!HOSTNAME_*}; do
	ip_var_name="HOSTIP${var_name#HOSTNAME}"
	host_entry="${!var_name}=${!ip_var_name}"
	hosts+=("$host_entry")
done
loadbalancers+=("${LOADBALANCER_HOST}=${LOADBALANCER_IP}")

mkdir certs
cp ./sources/ca-config.json ./certs/
cp ./sources/ca-csr.json ./certs/
cp ./sources/req-csr.json ./certs/
sed -i "s/LBHOST/${loadbalancers%%=*}/" "./certs/req-csr.json"

cfssl gencert -initca ./certs/ca-csr.json | cfssljson -bare ./certs/lb-ca
cfssl gencert -ca ./certs/lb-ca.pem -ca-key ./certs/lb-ca-key.pem -config ./certs/ca-config.json ./certs/req-csr.json | cfssljson -bare ./certs/${loadbalancers%%=*}
cat ./certs/${loadbalancers%%=*}-key.pem ./certs/${loadbalancers%%=*}.pem ./certs/lb-ca.pem > ./certs/${loadbalancers%%=*}-combined.pem

# Create base file
for host_info in "${hosts[@]}"; do
	hostname="${host_info%%=*}"
	cp ./certs/*.pem ./$hostname/
done
