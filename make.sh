#!/bin/bash
./makefolders.sh
./maketimesyncd.sh
./makekeepalived.sh
./make50-server.sh
./makerabbitmq.sh
./makememcached.sh
./makeetcd.sh
./makeapachekeystone.sh
./makekeystone.sh
./makeglanceapi.sh
