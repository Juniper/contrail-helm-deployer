# Installation guide for Contrail HA and Openstack-Helm Ocata

![Web Console](images/OpenContrail-Helm.png)
This installation procedure will use Juniper OpenStack Helm infra and OpenStack Helm repo for OpenStack/OpenContrail Ocata clsuter Multi-node deployment.

### Tested with

1. Operating system: Ubuntu 16.04.3 LTS
2. Kernel: 4.4.0-87-generic
3. docker: 1.13.1-cs9
4. helm: v2.7.2
5. kubernetes: v1.9.3
6. openstack: Ocata

### Pre-requisites

1. Generate SSH key on master node and copy to all nodes, in below example three nodes with IP addresses 10.13.82.43, 10.13.82.44 & 10.13.82.45 is used.

 ```bash
(k8s-master)> ssh-keygen

(k8s-master)> ssh-copy-id -i ~/.ssh/id_rsa.pub 10.13.82.43
(k8s-master)> ssh-copy-id -i ~/.ssh/id_rsa.pub 10.13.82.44
(k8s-master)> ssh-copy-id -i ~/.ssh/id_rsa.pub 10.13.82.45
 ```

2. Git clone the necessary repo's using below command on **all Nodes**

  ```bash
  # Download openstack-helm code
  (k8s-all-nodes)> git clone https://github.com/Juniper/openstack-helm.git /opt/openstack-helm
  # Download openstack-helm-infra code
  (k8s-all-nodes)> git clone https://github.com/Juniper/openstack-helm-infra.git /opt/openstack-helm-infra
  # Download contrail-helm-deployer code
  (k8s-all-nodes)> git clone https://github.com/Juniper/contrail-helm-deployer.git /opt/contrail-helm-deployer
  ```

3. Export variables needed by below procedure

  ```bash
  (k8s-master)> cd /opt
  (k8s-master)> export BASE_DIR=$(pwd)
  (k8s-master)> export OSH_PATH=${BASE_DIR}/openstack-helm
  (k8s-master)> export OSH_INFRA_PATH=${BASE_DIR}/openstack-helm-infra
  (k8s-master)> export CHD_PATH=${BASE_DIR}/contrail-helm-deployer
  ```

4. Installing necessary packages and deploying kubernetes

Edit `${OSH_INFRA_PATH}/tools/gate/devel/local-vars.yaml` if you would want to install a different version of kubernetes, cni, calico. This overrides the default values given in `${OSH_INFRA_PATH}/tools/gate/playbooks/vars.yaml`

  ```bash
  (k8s-master)> cd ${OSH_PATH}
  (k8s-master)> ./tools/deployment/developer/common/001-install-packages-opencontrail.sh
  ```

6. Create an inventory file on the master node for ansible base provisoning, please note in below output 10.13.82.43/.44/.45 are nodes IP addresses and will use SSK-key generated in step 1

 ```bash
 #!/bin/bash
(k8s-master)> set -xe
(k8s-master)> cat > /opt/openstack-helm-infra/tools/gate/devel/multinode-inventory.yaml <<EOF
all:
  children:
    primary:
      hosts:
        node_one:
          ansible_port: 22
          ansible_host: 10.13.82.43
          ansible_user: root
          ansible_ssh_private_key_file: /root/.ssh/id_rsa
          ansible_ssh_extra_args: -o StrictHostKeyChecking=no
    nodes:
      hosts:
        node_two:
          ansible_port: 22
          ansible_host: 10.13.82.44
          ansible_user: root
          ansible_ssh_private_key_file: /root/.ssh/id_rsa
          ansible_ssh_extra_args: -o StrictHostKeyChecking=no
        node_three:
          ansible_port: 22
          ansible_host: 10.13.82.45
          ansible_user: root
          ansible_ssh_private_key_file: /root/.ssh/id_rsa
          ansible_ssh_extra_args: -o StrictHostKeyChecking=no
EOF
 ```

7. Create an environment file on the master node for the cluster

 ```bash
(k8s-master)> cat > /opt/openstack-helm-infra/tools/gate/devel/multinode-vars.yaml <<EOF
kubernetes:
  network:
  cluster:
    cni: calico
    pod_subnet: 192.168.0.0/16
    domain: cluster.local
EOF
 ```

Note: In above example all interfaces configrued with defualt route will be used for k8s cluster creation.

8. Run the playbooks on master node

  ```bash
(k8s-master)> set -xe
(k8s-master)> cd ${OSH_INFRA_PATH}
(k8s-master)> make dev-deploy setup-host multinode
(k8s-master)> make dev-deploy k8s multinode
 ```

9. Verify kube-dns connection from all nodes.

Use `nslookup` to verify that you are able to resolve k8s cluster specific names

```bash
  (k8s-all-nodes)> nslookup
  > kubernetes.default.svc.cluster.local
  Server:         10.96.0.10
  Address:        10.96.0.10#53

  Non-authoritative answer:
  Name:   kubernetes.default.svc.cluster.local
  Address: 10.96.0.1
```

### Installation of OpenStack Helm Charts

All nodes by default labeled with "openstack-control-plane" and "openstack-compute-node" labels, you can use following commands to check opesnatck labels. With this default config OSH pods will be created on all the nodes.

```bash
(k8s-master)>  kubectl get nodes -o wide -l openstack-control-plane=enabled
(k8s-master)> kubectl get nodes -o wide -l openstack-compute-node=enabled
```

* **Note**: If requried please disable openstack labels using following commands to restrict OSH pods creation on specific nodes. In following example "openstack-compute-node" lable is disabled on "ubuntu-contrail-9" node.

```bash
(k8s-master)> kubectl label node ubuntu-contrail-9 --overwrite openstack-compute-node=disabled
```

1. Deploy OpenStack Helm charts using following commands.

```bash
  (k8s-master)> set -xe
  (k8s-master)> cd ${OSH_PATH}

  (k8s-master)> ./tools/deployment/multinode/010-setup-client.sh
  (k8s-master)> ./tools/deployment/multinode/021-ingress-opencontrail.sh
  (k8s-master)> ./tools/deployment/multinode/030-ceph.sh
  (k8s-master)> ./tools/deployment/multinode/040-ceph-ns-activate.sh
  (k8s-master)> ./tools/deployment/multinode/050-mariadb.sh
  (k8s-master)> ./tools/deployment/multinode/060-rabbitmq.sh
  (k8s-master)> ./tools/deployment/multinode/070-memcached.sh
  (k8s-master)> ./tools/deployment/multinode/080-keystone.sh
  (k8s-master)> ./tools/deployment/multinode/090-ceph-radosgateway.sh
  (k8s-master)> ./tools/deployment/multinode/100-glance.sh
  (k8s-master)> ./tools/deployment/multinode/110-cinder.sh
  (k8s-master)> ./tools/deployment/multinode/131-libvirt-opencontrail.sh
  (k8s-master)>./tools/deployment/multinode/141-compute-kit-opencontrail.sh

Note: Optional Horizon
(k8s-master)> ./tools/deployment/developer/ceph/100-horizon.sh
```

#### Installation of Contrail Helm charts

1. All contrail pods will be deployed in Namespace "contrail". Lable Contrail Nodes using below command and following labels are used by Contrail

* Control Nodes: opencontrail.org/controller
* vRouter Kernel: opencontrail.org/vrouter-kernel
* vRouter DPDK: opencontrail.org/vrouter-dpdk

In following example "ubuntu-contrail-11" is DPDK and "ubuntu-contrail-10" is kernel vrouter.

 ```bash
(k8s-master)> kubectl label node  ubuntu-contrail-11 opencontrail.org/vrouter-dpdk=enabled
(k8s-master)> kubectl label node ubuntu-contrail-10 opencontrail.org/vrouter-kernel=enabled
(k8s-master)> kubectl label nodes ubuntu-contrail-9 ubuntu-contrail-10 ubuntu-contrail-11 opencontrail.org/controller=enabled
 ```

2. K8s clusterrolebinding for contrail

 ```bash
(k8s-master)> cd $CHD_PATH
(k8s-master)> kubectl replace -f ${CHD_PATH}/rbac/cluster-admin.yaml
  ```

3. Now deploy opencontrail charts

```bash
 (k8s-master)> cd $CHD_PATH
 (k8s-master)> make

  # Set the IP of your CONTROLLER_NODES in each chart values.yaml and BGP port for multi-node setup (specify your control data ip, if you have one). Please note in below example 10.13.82.0/24 is MGMT & K8S clsuter host network and 192.168.1.0/24 is Contrail "Control-Data" network.
  CONTROLLER_NODES=10.13.82.43,10.13.82.44,10.13.82.45
  CONTROL_NODES: 192.168.1.43,192.168.1.44,192.168.1.45
  BGP_PORT=1179

  # set the control data network cidr list separated by comma and set the respective gateway
  CONTROL_DATA_NET_LIST=192.168.1.0/24
  VROUTER_GATEWAY=192.168.1.1
  AGENT_MODE: nic
```

Here are each chart **"contrail_env"** reference values.yaml file (**FYI**)

* **contrail-thirdparty/values.yaml**

```Text
contrail_env:
  CONTROLLER_NODES: 10.13.82.237,10.13.82.238,10.13.82.239
  LOG_LEVEL: SYS_NOTICE
  CLOUD_ORCHESTRATOR: openstack
  AAA_MODE: cloud-admin
```

* **contrail-controller/values.yaml**

```Text
contrail_env:
  CONTROL_NODES: 192.168.1.237,192.168.1.238,192.168.1.239
  CONTROLLER_NODES: 10.13.82.237,10.13.82.238,10.13.82.239
  LOG_LEVEL: SYS_NOTICE
  CLOUD_ORCHESTRATOR: openstack
  AAA_MODE: cloud-admin
  BGP_PORT: 1179
```

* **contrail-analytics/values.yaml**

```Text
contrail_env:
  CONTROLLER_NODES: 10.13.82.237,10.13.82.238,10.13.82.239
  LOG_LEVEL: SYS_NOTICE
  CLOUD_ORCHESTRATOR: openstack
  AAA_MODE: cloud-admin
```

* **contrail-vrouter/values.yaml**

```Text
contrail_env:
  CONTROLLER_NODES: 10.13.82.237,10.13.82.238,10.13.82.239
  CONTROL_NODES: 192.168.1.237,192.168.1.238,192.168.1.239
  LOG_LEVEL: SYS_NOTICE
  CLOUD_ORCHESTRATOR: openstack
  AAA_MODE: cloud-admin
  CONTROL_DATA_NET_LIST: 192.168.1.0/24
  VROUTER_GATEWAY: 192.168.1.1
contrail_env_vrouter_kernel:
  AGENT_MODE: nic
```

Here are helm install commands to deploy Contrail helm chart after setting configuration parameters in "values.yaml" files.

```bash
  (k8s-master)> helm install --name contrail-thirdparty ${CHD_PATH}/contrail-thirdparty \
  --namespace=contrail

  (k8s-master)> helm install --name contrail-controller ${CHD_PATH}/contrail-controller \
  --namespace=contrail

  (k8s-master)> helm install --name contrail-analytics ${CHD_PATH}/contrail-analytics \
  --namespace=contrail

  # Edit contrail-vrouter/values.yaml and make sure that images.tags.vrouter_kernel_init is right. Image tag name will be different depending upon your linux. Also set the conf.host_os to ubuntu or centos depending on your system

  (k8s-master)> helm install --name contrail-vrouter ${CHD_PATH}/contrail-vrouter \
  --namespace=contrail
```

4. Once Contrail PODs are up and running deploy OpenStack Heat chart using following command.

```bash
(k8s-master)> ./tools/deployment/multinode/151-heat-opencontrail.sh
```

### OSH Contrail Helm Clsuter basic testing

1. Basic Virtual Network and VMs testing

 ```bash
(k8s-master)> export OS_CLOUD=openstack_helm

(k8s-master)> openstack network create MGMT-VN
(k8s-master)> openstack subnet create --subnet-range 172.16.1.0/24 --network MGMT-VN MGMT-VN-subnet

(k8s-master)> openstack server create --flavor m1.tiny --image 'Cirros 0.3.5 64-bit' \
--nic net-id=MGMT-VN \
Test-01

(k8s-master)> openstack server create --flavor m1.tiny --image 'Cirros 0.3.5 64-bit' \
--nic net-id=MGMT-VN \
Test-02
 ```

### Reference

* <https://github.com/Juniper/openstack-helm/blob/master/doc/source/install/multinode.rst>

### [FAQ's](faq.md)
