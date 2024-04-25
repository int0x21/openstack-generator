#!/bin/bash

source hosts.conf
declare -a hosts

password_file="passwords.conf"
passwordkeystone=$(grep 'KEYSTONE_PASSWORD' "$password_file" | cut -d'=' -f2)
passwordglance=$(grep 'GLANCE_PASSWORD' "$password_file" | cut -d'=' -f2)
passwordnova=$(grep 'NOVA_PASSWORD' "$password_file" | cut -d'=' -f2)
passwordneutron=$(grep 'NEUTRON_PASSWORD' "$password_file" | cut -d'=' -f2)
passwordplacement=$(grep 'PLACEMENT_PASSWORD' "$password_file" | cut -d'=' -f2)
passwordcinder=$(grep 'CINDER_PASSWORD' "$password_file" | cut -d'=' -f2)

cp ./sources/dbprep.db .
sed -i "s/KEYSTONE_PASSWORD/$passwordkeystone/" "./dbprep.db"
sed -i "s/GLANCE_PASSWORD/$passwordglance/" "./dbprep.db"
sed -i "s/NOVA_PASSWORD/$passwordnova/" "./dbprep.db"
sed -i "s/NEUTRON_PASSWORD/$passwordneutron/" "./dbprep.db"
sed -i "s/PLACEMENT_PASSWORD/$passwordplacement/" "./dbprep.db"
sed -i "s/CINDER_PASSWORD/$passwordcinder/" "./dbprep.db"

sudo mysql < ./dbprep.db
cat dbprep.db

rm dbprep.db
