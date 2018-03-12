#!/bin/bash
set -ex
cd ${OSH_PATH}
./tools/deployment/developer/common/001-install-packages-opencontrail.sh
./tools/deployment/developer/common/010-deploy-k8s.sh

#Install openstack and heat client
./tools/deployment/developer/common/020-setup-client.sh

#Deploy openstack-helm related charts
./tools/deployment/developer/nfs/030-ingress.sh
./tools/deployment/developer/nfs/040-nfs-provisioner.sh
./tools/deployment/developer/nfs/050-mariadb.sh
./tools/deployment/developer/nfs/060-rabbitmq.sh
./tools/deployment/developer/nfs/070-memcached.sh
./tools/deployment/developer/nfs/080-keystone.sh
./tools/deployment/developer/nfs/100-horizon.sh
./tools/deployment/developer/nfs/120-glance.sh
./tools/deployment/developer/nfs/151-libvirt-opencontrail.sh
./tools/deployment/developer/nfs/161-compute-kit-opencontrail.sh

#Now deploy opencontrail charts
cd $CHD_PATH
make

#Label nodes with contrail specific labels
kubectl label node opencontrail.org/controller=enabled --all
kubectl label node opencontrail.org/vrouter-kernel=enabled --all

#Give cluster-admin permission for the user to create contrail pods
kubectl replace -f rbac/cluster-admin.yaml

# override default docker tags from values.yaml for opencontrail containers
helm install \
	--name contrail-thirdparty ${CHD_PATH}/contrail-thirdparty \
	--namespace=contrail \
	--set contrail_env.CONTROLLER_NODES=${DOCKER_BRIDGE} \
        --set images.tags.cassandra="$CONTRAIL_REGISTRY/contrail-external-cassandra:$CONTAINER_TAG" \
        --set images.tags.kafka="$CONTRAIL_REGISTRY/contrail-external-kafka:$CONTAINER_TAG" \
        --set images.tags.zookeeper="$CONTRAIL_REGISTRY/contrail-external-zookeeper:$CONTAINER_TAG"
bash ${OSH_PATH}/tools/deployment/common/wait-for-pods.sh contrail

helm install \
	--name contrail-controller ${CHD_PATH}/contrail-controller \
	--namespace=contrail \
        --set contrail_env.CONTROLLER_NODES=${DOCKER_BRIDGE} \
        --set contrail_env.CONTROL_NODES=${CONTROL_NODE} \
        --set images.tags.config_api="$CONTRAIL_REGISTRY/contrail-controller-config-api:$CONTAINER_TAG" \
        --set images.tags.config_devicemgr="$CONTRAIL_REGISTRY/contrail-controller-config-devicemgr:$CONTAINER_TAG" \
        --set images.tags.config_schema_transformer="$CONTRAIL_REGISTRY/contrail-controller-config-schema:$CONTAINER_TAG" \
        --set images.tags.config_svcmonitor="$CONTRAIL_REGISTRY/contrail-controller-config-svcmonitor:$CONTAINER_TAG" \
        --set images.tags.contrail_control="$CONTRAIL_REGISTRY/contrail-controller-control-control:$CONTAINER_TAG" \
        --set images.tags.control_dns="$CONTRAIL_REGISTRY/contrail-controller-control-dns:$CONTAINER_TAG" \
        --set images.tags.control_named="$CONTRAIL_REGISTRY/contrail-controller-control-named:$CONTAINER_TAG" \
        --set images.tags.nodemgr="$CONTRAIL_REGISTRY/contrail-nodemgr:$CONTAINER_TAG" \
        --set images.tags.webui_middleware="$CONTRAIL_REGISTRY/contrail-controller-webui-job:$CONTAINER_TAG" \
        --set images.tags.webui="$CONTRAIL_REGISTRY/contrail-controller-webui-web:$CONTAINER_TAG"
bash ${OSH_PATH}/tools/deployment/common/wait-for-pods.sh contrail 600

helm install \
	--name contrail-analytics ${CHD_PATH}/contrail-analytics \
	--namespace=contrail \
        --set contrail_env.CONTROLLER_NODES=${DOCKER_BRIDGE} \
        --set images.tags.analytics_alarm_gen="$CONTRAIL_REGISTRY/contrail-analytics-alarm-gen:$CONTAINER_TAG" \
        --set images.tags.analytics_api="$CONTRAIL_REGISTRY/contrail-analytics-api:$CONTAINER_TAG" \
        --set images.tags.analytics_query_engine="$CONTRAIL_REGISTRY/contrail-analytics-query-engine:$CONTAINER_TAG" \
        --set images.tags.analytics_snmp_collector="$CONTRAIL_REGISTRY/contrail-analytics-snmp-collector:$CONTAINER_TAG" \
        --set images.tags.contrail_collector="$CONTRAIL_REGISTRY/contrail-analytics-collector:$CONTAINER_TAG" \
        --set images.tags.contrail_topology="$CONTRAIL_REGISTRY/contrail-analytics-topology:$CONTAINER_TAG" \
        --set images.tags.nodemgr="$CONTRAIL_REGISTRY/contrail-nodemgr:$CONTAINER_TAG"
bash ${OSH_PATH}/tools/deployment/common/wait-for-pods.sh contrail

helm install --name contrail-vrouter ${CHD_PATH}/contrail-vrouter \
  --namespace=contrail \
	--set contrail_env.CONTROL_NODES=${CONTROL_NODE} \
        --set contrail_env.vrouter_common.CONTROLLER_NODES=${DOCKER_BRIDGE} \
        --set contrail_env.vrouter_common.PHYSICAL_INTERFACE="${PHYSICAL_INTERFACE}" \
        --set contrail_env.vrouter_common.VROUTER_GATEWAY="None" \
        --set images.tags.build_driver_init="$CONTRAIL_REGISTRY/contrail-agent-build-driver-init:$VROUTER_CONTAINER_TAG" \
        --set images.tags.dpdk_watchdog="$CONTRAIL_REGISTRY/contrail-agent-net-watchdog:$CONTAINER_TAG" \
        --set images.tags.nodemgr="$CONTRAIL_REGISTRY/contrail-nodemgr:$CONTAINER_TAG" \
        --set images.tags.vrouter_agent="$CONTRAIL_REGISTRY/contrail-agent-vrouter:$CONTAINER_TAG" \
        --set images.tags.vrouter_init_kernel="$CONTRAIL_REGISTRY/contrail-agent-vrouter-init-kernel:$CONTAINER_TAG" \
        --set images.tags.vrouter_vrouter_dpdk="$CONTRAIL_REGISTRY/contrail-agent-vrouter-dpdk:$CONTAINER_TAG" \
        --set images.tags.vrouter_init_dpdk="$CONTRAIL_REGISTRY/contrail-agent-vrouter-init-kernel-dpdk:$CONTAINER_TAG"
bash ${OSH_PATH}/tools/deployment/common/wait-for-pods.sh contrail

# Deploying heat charts after contrail charts are deployed as they have dependency on contrail charts
cd ${OSH_PATH}
make build-helm-toolkit
make build-heat
./tools/deployment/developer/nfs/091-heat-opencontrail.sh
