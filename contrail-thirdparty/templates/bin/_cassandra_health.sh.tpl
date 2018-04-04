#!/bin/bash -e

{{- $nodes := "CASSANDRA_SEEDS" }}
{{ tuple $nodes | include "helm-toolkit.contrail.find_my_node_ip" }}

if ! nodetool status -p "$CASSANDRA_JMX_LOCAL_PORT" | grep -E "^UN\\s+$my_ip"; then
  echo "ERROR: Nodetool status: "
  echo "$(nodetool status -p $CASSANDRA_JMX_LOCAL_PORT)"
  exit 1
fi
