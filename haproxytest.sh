#!/bin/bash

haversion=$(grep _version /etc/haproxy/haproxy.cfg | awk -F'=' '{print $2}')
echo $haversion

curl -u admin:HAPROXY_PASSWORD -X POST "http://localhost:5555/v2/services/haproxy/configuration/servers?backend=neutron_api_backend&version=$haversion" \
    -H "Content-Type: application/json" \
    -d '{
          "check": "enabled",
          "fall": 5,
          "inter": 10000,
          "rise": 2,
          "address": "172.30.1.15",
          "name": "host-os-06",
          "port": 9696
	}'

