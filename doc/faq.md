# FAQ's

### Config

1. Use `manifests.each_container_is_pod` variable to make each contrail service run as a single pod. Otherwise services under control, config, webui, analytics and vrouter components are grouped into a pod

1. How to setup vhost0 interface for vrouter on non-mgmt interface of your compute node?
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

2. How to configure contrail control BGP server to listen on a different port?

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

  [OpenContrail Cluster Access Doc] (contrail-osh-cluster-access.md)
