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

2. Git clone the necessary repo's using below command on all Nodes

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

4. Change Calico Felix Prometheus Monitoring Port from "9091" to "9099". Please note port 9091 is used by vRouter and should not be used another application on compute nodes.

 ```bash
(k8s-master)> vim ${OSH_INFRA_PATH}/calico/values.yaml 

Old-Value= "port: 9091"
New-Value= "port: 9099"

Old-Value= "FELIX_PROMETHEUSMETRICSPORT: \"9091\""
New-Value= "FELIX_PROMETHEUSMETRICSPORT: \"9099\""
 ```

5. Create an inventory file on the master node for ansible base provisoning, please note in below output 10.13.82.43/.44/.45 are nodes IP addresses and will use SSK-key generated in step 1 

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

6. Create an environment file on the master node for the cluster

 ```bash
(k8s-master)> set -xe

(k8s-master)> function net_default_iface {
 sudo ip -4 route list 0/0 | awk '{ print $5; exit }'
}

(k8s-master)> cat > /opt/openstack-helm-infra/tools/gate/devel/multinode-vars.yaml <<EOF
kubernetes:
  network:
    default_device: $(net_default_iface)
  cluster:
    cni: calico
    pod_subnet: 192.168.0.0/16
    domain: cluster.local
EOF
 ```

7. Run the playbooks on master node

  ```bash
(k8s-master)> set -xe
(k8s-master)> cd ${OSH_INFRA_PATH}
(k8s-master)> make dev-deploy setup-host multinode
(k8s-master)> make dev-deploy k8s multinode
 ```

8. Verify kube-dns connection from all nodes.

Add kube-dns svc IP as one of your dns server also add k8s cluster domain as search domain.

Note: Install nslookup if it's not installed already

 ```bash
 (k8s-all-nodes)> apt-get install dnsutils -y
 ```

```bash
  # Example
  # cat /etc/resolv.conf
  nameserver 10.96.0.10
  nameserver 10.84.5.100
  search openstack.svc.cluster.local svc.cluster.local contrail.juniper.netjuniper.netjnpr.net
```

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

9.Installing necessary packages and deploying kubernetes

Edit `${OSH_INFRA_PATH}/tools/gate/devel/local-vars.yaml` if you would want to install a different version of kubernetes, cni, calico. This overrides the default values given in `${OSH_INFRA_PATH}/tools/gate/playbooks/vars.yaml`

  ```bash
  (k8s-master)> cd ${OSH_PATH}
  (k8s-master)> ./tools/deployment/developer/common/000-install-packages.sh
  (k8s-master)> ./tools/deployment/developer/common/001-install-packages-opencontrail.sh
  ```

### Installation of OpenStack Helm Charts

Deploy OpenStack Helm charts using following commands.

 ```bash
  (k8s-master)> set -xe
  (k8s-master)> cd ${OSH_PATH}

  (k8s-master)> ./tools/deployment/multinode/010-setup-client.sh
  (k8s-master)> ./tools/deployment/multinode/020-ingress.sh
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

Deploy Heat Chart after deploying Contrail helm charts
  (k8s-master)> ./tools/deployment/multinode/151-heat-opencontrail.sh
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
(k8s-master)> kubectl replace -f ${OSH_PATH}/tools/kubeadm-aio/assets/opt/rbac/dev.yaml
  ```

3. Now deploy opencontrail charts

  ```bash
 (k8s-master)> cd $CHD_PATH
 (k8s-master)> make

  # Set the IP of your CONTROLLER_NODES in each chart values.yaml and BGP port for multi-node setup (specify your control data ip, if you have one)
  CONTROLLER_NODES=192.168.1.43,192.168.1.44,192.168.1.45
  BGP_PORT=1179

  # set the control data network cidr list separated by comma and set the respective gateway
  CONTROL_DATA_NET_LIST=192.168.1.0/24
  VROUTER_GATEWAY=192.168.1.1
  AGENT_MODE: nic

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

### OSH Contrail Helm Clsuter basic testing

 ```bash
export OS_CLOUD=openstack_helm

openstack network create MGMT-VN
openstack subnet create --subnet-range 172.16.1.0/24 --network MGMT-VN MGMT-VN-subnet

openstack server create --flavor m1.tiny --image 'Cirros 0.3.5 64-bit' \
    --nic net-id=MGMT-VN \
    --availability-zone nova:ubuntu-contrail-10 \
Test-01

openstack server create --flavor m1.tiny --image 'Cirros 0.3.5 64-bit' \
    --nic net-id=MGMT-VN \
    --availability-zone nova:ubuntu-contrail-11 \
Test-02
 ```

### [FAQ's](faq.md)