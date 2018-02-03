# Installation guide for Contrail HA and Openstack-Helm

### Tested with

1. Operating system: Ubuntu 16.04.3 LTS
2. Kernel: 4.4.0-87-generic
3. docker: 1.13.1
4. helm: v2.7.2
5. kubernetes: v1.8.3
6. openstack: newton

### Pre-requisites

1. Have a kubernetes cluster up and running ([Quickstart steps to bring up a k8s cluster](installing_k8s.md))

2. Have helm installed and intitialized ([Steps to install and initialize helm](installing_helm.md))

3. Install below software's on all nodes
  ```bash
  sudo apt-get install -y ceph-common \
        make \
        git \
        linux-headers-$(uname -r)
  ```

4. Add kube-dns svc IP as one of your dns server also add k8s cluster domain as search domain

  ```bash
  # Example
  root@b7s32:~# cat /etc/resolv.conf
  nameserver 10.96.0.10
  nameserver 10.84.5.100
  search openstack.svc.cluster.local svc.cluster.local contrail.juniper.netjuniper.netjnpr.net
  ```

  Use `nslookup` to verify that you are able to resolve k8s cluster specific names
  ```bash
  root@b7s32:~# nslookup
  > kubernetes.default.svc.cluster.local
  Server:         10.96.0.10
  Address:        10.96.0.10#53

  Non-authoritative answer:
  Name:   kubernetes.default.svc.cluster.local
  Address: 10.96.0.1
  ```

5. Updating ClusterRole (This is needed by contrail pods for now)

  ```bash
  kubectl replace -f \
  https://raw.githubusercontent.com/madhukar32/openstack-helm/contrail_5_0/tools/kubeadm-aio/assets/opt/rbac/dev.yaml
  ```


#### Installation steps

1. Get openstack-helm and contrail-helm-deployer repo

  ```bash
  # Download openstack-helm code
  git clone https://github.com/madhukar32/openstack-helm.git -b contrail_5_0
  git clone https://github.com/Juniper/contrail-helm-deployer.git

  # Exporting variables

  export BASE_DIR=$(pwd)
  export OSH_PATH=${BASE_DIR}/openstack-helm
  export CHD_PATH=${BASE_DIR}/contrail-helm-deployer
  ```

2. Labelling nodes for openstack, contrail, ceph and compute

  ```bash
  # Here b7s32 b7s33 b7s34 b7s35 b7s36 are sample nodes
  kubectl label nodes b7s32 openstack-control-plane=enabled
  kubectl label nodes b7s32 b7s33 b7s34 ceph-mon=enabled
  kubectl label nodes b7s32 b7s33 b7s34 ceph-osd=enabled
  kubectl label nodes b7s32 b7s33 b7s34 ceph-mds=enabled
  kubectl label nodes b7s32 b7s33 b7s34 ceph-rgw=enabled
  kubectl label nodes b7s32 b7s33 b7s34 ceph-mgr=enabled
  kubectl label nodes b7s35 b7s36 openstack-compute-node=enabled
  kubectl label nodes b7s32 b7s33 b7s34 opencontrail.org/controller=enabled
  ```

4. Make all OSH charts

  ```bash
  cd ${OSH_PATH}
  make
  ```

3. Deploying Ceph charts

  ```bash
  # 10.84.29.32/24 is a network on which your k8s cluster is running
  export OSD_CLUSTER_NETWORK=10.84.29.32/24
  export OSD_PUBLIC_NETWORK=10.84.29.32/24

  cd ${OSH_PATH}
  : ${CEPH_RGW_KEYSTONE_ENABLED:="true"}
  helm install --namespace=ceph ${OSH_PATH}/ceph --name=ceph \
    --set endpoints.identity.namespace=openstack \
    --set endpoints.object_store.namespace=ceph \
    --set endpoints.ceph_mon.namespace=ceph \
    --set ceph.rgw_keystone_auth=${CEPH_RGW_KEYSTONE_ENABLED} \
    --set network.public=${OSD_PUBLIC_NETWORK} \
    --set network.cluster=${OSD_CLUSTER_NETWORK} \
    --set deployment.storage_secrets=true \
    --set deployment.ceph=true \
    --set deployment.rbd_provisioner=true \
    --set deployment.cephfs_provisioner=true \
    --set deployment.client_secrets=false \
    --set deployment.rgw_keystone_user_and_endpoints=false \
    --set bootstrap.enabled=true
  ```

  Verifying all ceph pods are up

  ```bash
  kubectl get pods -n ceph
  ```

  Checking the health of ceph

  ```bash
  MON_POD=$(kubectl get pods \
  --namespace=ceph \
  --selector="application=ceph" \
  --selector="component=mon" \
  --no-headers | awk '{ print $1; exit }')
  kubectl exec -n ceph ${MON_POD} -- ceph -s
  ```

  Activating control-plane namespace for ceph

  ```bash
  : ${CEPH_RGW_KEYSTONE_ENABLED:="true"}
  helm install --namespace=openstack ${OSH_PATH}/ceph --name=ceph-openstack-config \
  --set endpoints.identity.namespace=openstack \
  --set endpoints.object_store.namespace=ceph \
  --set endpoints.ceph_mon.namespace=ceph \
  --set ceph.rgw_keystone_auth=${CEPH_RGW_KEYSTONE_ENABLED} \
  --set network.public=${OSD_PUBLIC_NETWORK} \
  --set network.cluster=${OSD_CLUSTER_NETWORK} \
  --set deployment.storage_secrets=false \
  --set deployment.ceph=false \
  --set deployment.rbd_provisioner=false \
  --set deployment.cephfs_provisioner=false \
  --set deployment.client_secrets=true \
  --set deployment.rgw_keystone_user_and_endpoints=false
  ```

4. Installing Mariadb chart

  ```bash
  helm install --name=mariadb ${OSH_PATH}/mariadb --namespace=openstack
  ```

5. Install rabbitmq, etcd, libvirt, ingress, memcached charts

  ```bash
  helm install --name=memcached ${OSH_PATH}/memcached --namespace=openstack
  helm install --name=etcd-rabbitmq ${OSH_PATH}/etcd --namespace=openstack
  helm install --name=rabbitmq ${OSH_PATH}/rabbitmq --namespace=openstack
  helm install --name=ingress ${OSH_PATH}/ingress --namespace=openstack
  helm install --name=libvirt ${OSH_PATH}/libvirt --namespace=openstack -f ${OSH_PATH}/tools/overrides/mvp/libvirt-opencontrail.yaml
  ```

6. Installing keystone chart

  ```bash
  helm install --namespace=openstack --name=keystone ${OSH_PATH}/keystone \
  --set pod.replicas.api=1
  ```

7. Install Rados GW object storage

  ```bash
  helm install --namespace=openstack ${OSH_PATH}/ceph --name=radosgw-openstack \
  --set endpoints.identity.namespace=openstack \
  --set endpoints.object_store.namespace=ceph \
  --set endpoints.ceph_mon.namespace=ceph \
  --set ceph.rgw_keystone_auth=${CEPH_RGW_KEYSTONE_ENABLED} \
  --set network.public=${OSD_PUBLIC_NETWORK} \
  --set network.cluster=${OSD_CLUSTER_NETWORK} \
  --set deployment.storage_secrets=false \
  --set deployment.ceph=false \
  --set deployment.rbd_provisioner=false \
  --set deployment.client_secrets=false \
  --set deployment.cephfs_provisioner=false \
  --set deployment.rgw_keystone_user_and_endpoints=true
  ```

8. Install horizon

  ```bash
  helm install --namespace=openstack --name=horizon ${OSH_PATH}/horizon \
  --set network.node_port.enabled=true
  ```

9. Install Glance

  ```bash
  : ${GLANCE_BACKEND:="radosgw"}
  helm install --namespace=openstack --name=glance ${OSH_PATH}/glance \
  --set pod.replicas.api=2 \
  --set pod.replicas.registry=2 \
  --set storage=${GLANCE_BACKEND}
  ```

10. Preparing contrail charts

  ```bash
  cd ${CHD_PATH}
  #build all charts
  make

  # Edit contrail-thirdparty/values.yaml, contrail-controller/values.yaml,
  # contrail-analytics/values.yaml, contrail-vrouter/values.yaml and
  # add list of CONTROLLER_NODES IP seperated by comma
  # sample
  contrail_env:
    CONTROLLER_NODES: 10.84.29.32,10.84.29.33,10.84.29.34
  ```

11. Installing contrail charts

  ```bash
  helm install --name contrail-thirdparty ${CHD_PATH}/contrail-thirdparty \
  --namespace=openstack

  helm install --name contrail-controller ${CHD_PATH}/contrail-controller \
  --namespace=openstack \
  --set manifests.each_container_is_pod=true

  helm install --name contrail-analytics ${CHD_PATH}/contrail-analytics \
  --namespace=openstack  \
  --set manifests.each_container_is_pod=true

  helm install --name contrail-vrouter ${CHD_PATH}/contrail-vrouter \
  --namespace=openstack  \
  --set manifests.each_container_is_pod=true
  ```

12. Installing neutron

  ```bash
  cd ${OSH_PATH}
  #CAVEAT: Give only one IP of config node as of now
  export CONFIG_NODE=10.84.29.32
  helm install ${OSH_PATH}/neutron --namespace=openstack \
  --name=neutron --values=${OSH_PATH}/tools/overrides/mvp/neutron-opencontrail.yaml \
  --set conf.plugins.opencontrail.APISERVER.api_server_ip=${CONFIG_NODE} \
  --set conf.plugins.opencontrail.COLLECTOR.analytics_api_ip=${ANALYTICS_NODES:-${CONFIG_NODE}}
  ```
13. Deploying Nova

  ```bash
  helm install ${OSH_PATH}/nova \
      --namespace=openstack \
      --values=${OSH_PATH}/tools/overrides/mvp/nova-opencontrail.yaml \
      --name=nova
  ```

### [FAQ's](faq.md)
