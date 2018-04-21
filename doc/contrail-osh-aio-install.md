# All-in-one openstack-helm with contrail cluster (NON-HA)

Using below step you can bring an all-in-one cluster with openstack and contrail

### Tested with

1. Operating system: Ubuntu 16.04.3 LTS
2. Kernel: 4.4.0-87-generic
3. docker: 1.13.1
4. helm: v2.7.2
5. kubernetes: v1.8.3
6. openstack: ocata

### Resource spec (used for internal validation)

1. CPU: 8
2. RAM: 32 GB
3. HDD: 120 GB

### Pre-req packages

Install below packages on your setup

```bash
  git
```

### Installation steps

1. Git clone the necessary repo's using below command
  ```bash
  # Download openstack-helm code
  git clone https://github.com/Juniper/openstack-helm.git
  # Download openstack-helm-infra code
  git clone https://github.com/Juniper/openstack-helm-infra.git
  # Download contrail-helm-deployer code
  git clone https://github.com/Juniper/contrail-helm-deployer.git
  ```

2. Export variables needed by below procedure

  ```bash
  export BASE_DIR=$(pwd)
  export OSH_PATH=${BASE_DIR}/openstack-helm
  export OSH_INFRA_PATH=${BASE_DIR}/openstack-helm-infra
  export CHD_PATH=${BASE_DIR}/contrail-helm-deployer
  ```

2. Installing necessary packages and deploying kubernetes

Edit `${OSH_INFRA_PATH}/tools/gate/devel/local-vars.yaml` if you would want to install a different version of kubernetes, cni, calico. This overrides the default values given in `${OSH_INFRA_PATH}/playbooks/vars.yaml`

  ```bash
  cd ${OSH_PATH}
  ./tools/deployment/developer/common/001-install-packages-opencontrail.sh
  ./tools/deployment/developer/common/010-deploy-k8s.sh
  ```

3. Install openstack and heat client

  ```bash
  ./tools/deployment/developer/common/020-setup-client.sh
  ```

4. Deploy openstack-helm related charts

  ```bash
  ./tools/deployment/developer/nfs/031-ingress-opencontrail.sh
  ./tools/deployment/developer/nfs/040-nfs-provisioner.sh
  ./tools/deployment/developer/nfs/050-mariadb.sh
  ./tools/deployment/developer/nfs/060-rabbitmq.sh
  ./tools/deployment/developer/nfs/070-memcached.sh
  ./tools/deployment/developer/nfs/080-keystone.sh
  ./tools/deployment/developer/nfs/100-horizon.sh
  ./tools/deployment/developer/nfs/120-glance.sh
  ./tools/deployment/developer/nfs/151-libvirt-opencontrail.sh
  ./tools/deployment/developer/nfs/161-compute-kit-opencontrail.sh
  ```

5. Now deploy opencontrail charts

  ```bash
  cd $CHD_PATH

  make

  # Set the IP of your CONTROL_NODES (specify your control data ip, if you have one)
  export CONTROL_NODES=10.87.65.245
  # set the control data network cidr list separated by comma and set the respective gateway
  export CONTROL_DATA_NET_LIST=10.87.65.128/25
  export VROUTER_GATEWAY=10.87.65.129

  kubectl label node opencontrail.org/controller=enabled --all
  kubectl label node opencontrail.org/vrouter-kernel=enabled --all

  kubectl replace -f ${CHD_PATH}/rbac/cluster-admin.yaml

  tee /tmp/contrail.yaml << EOF
  global:
    contrail_env:
      CONTROLLER_NODES: 172.17.0.1
      CONTROL_NODES: ${CONTROL_NODES}
      LOG_LEVEL: SYS_NOTICE
      CLOUD_ORCHESTRATOR: openstack
      AAA_MODE: cloud-admin
      CONTROL_DATA_NET_LIST: ${CONTROL_DATA_NET_LIST}
      VROUTER_GATEWAY: ${VROUTER_GATEWAY}
EOF

  helm install --name contrail ${CHD_PATH}/contrail \
  --namespace=contrail --values=/tmp/contrail.yaml
  ```

6. Deploy heat charts

  ```bash
  cd ${OSH_PATH}
  ./tools/deployment/developer/nfs/091-heat-opencontrail.sh
  ```
