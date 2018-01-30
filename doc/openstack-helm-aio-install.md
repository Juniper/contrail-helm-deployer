# All-in-one openstack-helm with contrail cluster

Using below step you can bring an all-in-one cluster with openstack and contrail

### Prerequisites

* Below are the list of pacakges which needs to be installed on you all-in-one node
  ```notes
  git
  ```

### Installation steps

1. Git clone the necessary repo's using below command
  ```bash
  # Download openstack-helm code
  git clone https://github.com/madhukar32/openstack-helm.git -b contrail_5_0
  # Download openstack-helm-infra code
  git clone https://github.com/madhukar32/openstack-helm-infra.git -b contrail_5_0
  # Download contrail-helm-deployer code
  git clone https://github.com/Juniper/contrail-helm-deployer.git
  ```

2. Export variables needed by below procedure

  ```bash
  export BASE_DIR=$(pwd)
  export OSH_PATH=${BASE_DIR}/openstack-helm
  export OSH_INFRA_PATH=${BASE_DIR}/openstack-helm-infra
  export CHD_PATH=${BASE_DIR}/contrail-helm-deployer
  # Set the IP of your controller node and config node
  export CONTROLLER_NODE=10.87.65.245
  export CONFIG_NODE=10.87.65.245
  ```

2. Installing necessary packages and deploying kubernetes

  Edit `${OSH_INFRA_PATH}/tools/gate/devel/local-vars.yaml` if you would want to install a different version of kubernetes, cni, calico. This overrides the default values given in `${OSH_INFRA_PATH}/tools/gate/playbooks/vars.yaml`

  ```bash
  cd ${BASE_DIR}/openstack-helm
  bash tools/deployment/developer/00-install-packages.sh
  bash tools/deployment/developer/01-deploy-k8s.sh
  ```

3. Add insecure docker registy

   [*To-do, need to make changes to openstack-helm-infra so that we can add insecure registry through the ansible playbook*]

  ```bash
  # In this case 10.87.65.243 is the IP on ehcih docker registry is hosted and 5000 is a port on which it is listening
  sudo bash -c 'cat << EOF > /etc/docker/daemon.json
  {
    "insecure-registries" : ["10.87.65.243:5000"]
  }
  EOF'

  service docker restart
  ```

4. Build all helm charts and intll openstack and heat client

  ```bash
  bash tools/deployment/developer/02-setup-client.sh
  ```

5. Deploy openstack-helm related charts

  ```bash
  bash tools/deployment/developer/03-ingress.sh
  bash tools/deployment/developer/04-ceph.sh
  bash tools/deployment/developer/05-ceph-ns-activate.sh
  bash tools/deployment/developer/06-mariadb.sh
  bash tools/deployment/developer/07-rabbitmq.sh
  bash tools/deployment/developer/08-memcached.sh
  bash tools/deployment/developer/09-keystone.sh
  bash tools/deployment/developer/10-ceph-radosgateway.sh
  bash tools/deployment/developer/11-horizon.sh
  bash tools/deployment/developer/12-glance.sh
  bash tools/deployment/developer/14-libvirt.sh
  ```

6. Now deploy opencontrail charts

  ```
  cd $CHD_PATH

  make

  kubectl label node opencontrail.org/controller=enabled --all

  kubectl replace -f ${OSH_PATH}/tools/kubeadm-aio/assets/opt/rbac/dev.yaml

  helm install --name contrail-thirdparty ${CHD_PATH}/contrail-thirdparty \
  --namespace=openstack --set contrail_env.CONTROLLER_NODES=${CONTROLLER_NODE} \
  --set manifests.each_container_is_pod=true

  helm install --name contrail-controller ${CHD_PATH}/contrail-controller \
  --namespace=openstack --set contrail_env.CONTROLLER_NODES=${CONTROLLER_NODE} \
  --set manifests.each_container_is_pod=true

  helm install --name contrail-analytics ${CHD_PATH}/contrail-analytics \
  --namespace=openstack --set contrail_env.CONTROLLER_NODES=${CONTROLLER_NODE} \
  --set manifests.each_container_is_pod=true

  # Edit contrail-vrouter/values.yaml and make sure that images.tags.agent_vrouter_init_kernel is right. Image tag name will be different depending upon your linux. Also set the conf.host_os to ubuntu or centos depending on your system

  helm install --name contrail-vrouter ${CHD_PATH}/contrail-vrouter \
  --namespace=openstack --set contrail_env.CONTROLLER_NODES=${CONTROLLER_NODE} \
  --set manifests.each_container_is_pod=true

  ```

7. Install remaining openstack charts

  ```bash
  cd $OSH_PATH
  bash tools/deployment/developer/15-compute-kit.sh
  bash tools/deployment/developer/17-cinder.sh
  bash tools/deployment/developer/18-heat.sh
  ```
