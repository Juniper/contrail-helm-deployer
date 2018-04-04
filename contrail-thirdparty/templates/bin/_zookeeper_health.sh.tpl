#!/bin/bash -e

{{- $nodes := "ZOOKEEPER_NODES" }}
{{ tuple $nodes | include "helm-toolkit.contrail.find_my_node_ip" }}

OK=$(echo ruok | nc $my_ip $ZOOKEEPER_PORT)
if [ "$OK" == "imok" ]; then
	exit 0
else
	exit 1
fi
