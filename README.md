# Contrail Helm based deployment

This repo consists of contrail helm charts which helps to deploy contrail networking components as microservices

___

## Architecure of contrail helm charts

Contrail-helm-deployer is divided into below charts

1. contrail-helper: Is a chart where common methods used in other contrail charts are defined. contrail-helper chart is a common requirement for every other chart
2. contrail-thrirdparty: Helps to install contrail thirdparty components like cassandra, zookepper, kafka and redis needed by other contrail charts
3. contrail-controller: Using this chart we can install contrail services related to config, control and webui components
4. contrail-analytics: Helps to install contrail analytics services
5. contrail-vrouter: Installs contrail vrouter services

Using .Values.manifests.each_container_is_pod variable we can make each contrail service run as a single pod. Otherwise services under control, config, webui, analytics and vrouter components are grouped into a pod

## Prerequisites

* Centos 7.4
* Centos kernel version: 3.10.0-693.5.2.el7.x86_64
* Docker version: Tested with 1.12.6
* helm version: Tested with v2.5.1
* kubernetes version: Tested with v1.7.4
* Have kubernetes cluster up and running
* Have openstack-helm charts up and running (To-do steps to bring up openstack-helm charts, with contrail related changes in it)

___

## Instructions to bring up contrail helm charts

1. Get the helm charts by cloning the repository

  ```console
  git clone https://github.com/Juniper/contrail-helm-deployer.git
  cd contrail-helm-deployer
  export WORK_DIR=$(pwd)
  ```

2. Make sure that you have helm server up and running (This is done while installing openstack-helm charts). Below is how you verify installation of helm server
  ```console
  $ helm repo list
  NAME    URL
  local   http://localhost:8879/charts
  ```

3. Use `make` command to initialize, build up the dependency and lint the charts
  ```console
  make
  ```

4. Edit below values.yaml file to change the IP of controller_nodes and also to point it to the correct docker_registry
  ```console
  vim contrail-thirdparty/values.yaml
  vim contrail-controller/values.yaml
  vim contrail-analytics/values.yaml
  vim contrail-vrouter/values.yaml
  ```

5. Install contrail components using the below command
  ```console
  helm install --name contrail-thirdparty \
  ${WORK_DIR}/contrail-thirdparty --namespace=openstack \
  --set manifests.each_container_is_pod=true
  #
  helm install --name contrail-controller \
  ${WORK_DIR}/contrail-controller --namespace=openstack \
  --set manifests.each_container_is_pod=true
  #
  helm install --name contrail-analytics \
  ${WORK_DIR}/contrail-analytics --namespace=openstack \
  --set manifests.each_container_is_pod=true
  #
  helm install --name contrail-vrouter \
  ${WORK_DIR}/contrail-vrouter --namespace=openstack \
  --set manifests.each_container_is_pod=true
  ```

___

## To-Do list

1. ~~Coming up with basic charts, adding Makefile and trying it with openstack-helm charts~~
2. ~~Having an option to deploy each container as a separate pod~~
3. ~~Separating out config-zookeeper and analytics-zookeeper~~
4. Exposing all ports used by each container in the container spec
5. Analyzing and adding resource limits for each of the contrail container
6. Adding lifecycle hooks to each of the container and making sure that we delete everything we create while deleting the container
7. Adding charts for DPDK vrouter
8. Support for SRIOV and SRIOV+DPDK coexistence using helm
9. Evaluating headless services for NB APIs and webui in contrail
10. Documentation for Contrail Helm charts in 5.0
  * Installation doc
  * High level Architecture doc for 5.0 charts
  * Troubleshooting 5.0 helm charts docs
11. Adding RBAC objects for each of the pod
12. Adding contrail-kubernetes related components
13. Support for adding TSN node
14. Test adding single vrouter at a time
15. Test contrail HA
16. Adding test cases for each of helm charts
17. Support for provisioning hybrid cloud connect
18. Patching contrail changes with the latest openstack-helm charts
