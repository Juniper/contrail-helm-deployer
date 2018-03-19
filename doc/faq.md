# FAQ's

### Config

1. Use `manifests.each_container_is_pod` variable to make each contrail service run as a single pod. Otherwise services under control, config, webui, analytics and vrouter components are grouped into a pod

2. How to setup vhost0 interface for vrouter on non-mgmt interface of your compute node?
  [to-do have to fix below caveat]
  Caveats: It assumes that non-mgmt interface name of all nodes in your cluster has same name

  If your non-mgmt interface is eth1, then you need to set
  `contrail_env.PHYSICAL_INTERFACE` to `eth1` and set `contrail_env.VROUTER_GATEWAY`
  to non-mgmt gateway IP in [contrail-vrouter/values.yaml](../contrail-vrouter/values.yaml)

  ```bash
  # Sample config
  contrail_env:
    CONTROLLER_NODES: 1.1.1.10
    LOG_LEVEL: SYS_NOTICE
    CLOUD_ORCHESTRATOR: openstack
    AAA_MODE: cloud-admin
    PHYSICAL_INTERFACE: eth1
    VROUTER_GATEWAY: 1.1.1.1
  ```

3. How to configure contrail control BGP server to listen on a different port?

  If you would like to configure a non default BGP port then set `contrail_env.BGP`
  in [contrail-controller/values.yaml](../contrail-controller/values.yaml)

  ```bash
  # Sample config
  contrail_env:
    CONTROLLER_NODES: 1.1.1.10
    LOG_LEVEL: SYS_NOTICE
    CLOUD_ORCHESTRATOR: openstack
    AAA_MODE: cloud-admin
    BGP_PORT: 1179
  ```

4. How to pass additional parameters to Contrails' services with configuration file in INI format?

  Please note that this is not related to WebUI service cause it has configuration file in JS format.
  To pass variable 'some_key' to set in section 'SOME_SECTION' of Contrail's service 'SOME_SERVICE' you need to add it in next way to environment:

  ```bash
  # Sample config
  contrail_env:
    SOME_SERVICE__SOME_SECTION__some_key: "value"
  ```

  Service's name, section's name and key's name are divided by two underscore symbols.

  For example if you would like to configure minimumin_diskGB parameter for node manager of analytics DB:

  ```bash
  # Sample config
  contrail_env:
    DATABASE_NODEMGR__DEFAULTS__minimum_diskGB: "2"
  ```

  Example for vrouter agent:

  ```bash
  # Sample config
  contrail_env:
    VROUTER_AGENT__FLOWS__thread_count: "2"
    VROUTER_AGENT__METADATA__metadata_use_ssl = True
    VROUTER_AGENT__METADATA__metadata_client_cert = /usr/share/ca-certificates/contrail/client_cert.pem
    VROUTER_AGENT__METADATA__metadata_client_key = /usr/share/ca-certificates/contrail/client_key.pem
    VROUTER_AGENT__METADATA__metadata_ca_cert = /usr/share/ca-certificates/contrail/cacert.pem
  ```

  List of config services for now is: SVC_MONITOR, API, DEVICE_MANAGER, SCHEMA, CONFIG_NODEMGR
  List of control services for now is: CONTROL, DNS, CONTROL_NODEMGR
  List of analytics services for now is: ALARM_GEN, TOPOLOGY, ANALYTICS_API, COLLECTOR, SNMP_COLLECTOR, QUERY_ENGINE, ANALYTICS_NODEMGR
  List of database services for now is: DATABASE_NODEMGR
  List of vrouter services for now is: VROUTER_AGENT, VROUTER_AGENT_NODEMGR

5. How to pass additional parameters to WebUI services with configuration file in JS format?

  Right now there is one one to do it - define exact variable in invironment like this:

  ```bash
  # Sample config
  contrail_env:
    WEBUI_SSL_CIPHERS: "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384"
  ```

  Available configuration settings can be found in source code only for now - https://github.com/Juniper/contrail-container-builder/blob/master/containers/controller/webui/base/entrypoint.sh#L31-L199

### Verification

1. How to verify all pods of contrail are up and running?

  Use below command to list all pods of contrail

  ```bash
  kubectl get pods -n openstack -o wide | grep contrail-
  ```

2. How to see logs of each of the container?

  Contrail logs are mounted under /var/log/contrail/ on each node and
  to check for stdout log for each container use `kubectl logs -f <contrail-pod-name> -n openstack`

3. How to enter into pod?

  Use command `kubectl exec -it <contrail-pod> -n openstack -- bash`

4. How to access Openstack Horizon and OpenContrail WebUI?

  [OpenContrail Cluster Access Doc](contrail-osh-cluster-access.md)
