{{- define "helm-toolkit.contrail.find_my_node_ip" -}}

{{- $nodes := index . 0 }}
IFS=',' read -ra srv_list <<< "${{ $nodes }}"
local_ips=",$(cat "/proc/net/fib_trie" | awk '/32 host/ { print f } {f=$2}' | tr '\n' ','),"
for srv in "${srv_list[@]}"; do
  if [[ "$local_ips" =~ ",$srv," ]] ; then
    echo "INFO: found '$srv' in local IPs '$local_ips'"
    my_ip=$srv
    break
  fi
done

if [ -z "$my_ip" ]; then
  echo "ERROR: Cannot find self ips ('$local_ips') in Cassandra nodes ('$CASSANDRA_SEEDS')"
  exit 1
fi
{{- end -}}
