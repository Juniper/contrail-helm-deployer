#!/bin/bash
set -ex
cd ${OSH_PATH}

#Get physical_intf and ip address
physical_intf="$(sudo ip -4 route list 0/0 | awk '{ print $5; exit }')"
intf_ip_address="$(ip addr show dev $physical_intf | grep "inet .*/.* brd " | awk '{print $2}' | cut -d '/' -f 1)"

./tools/deployment/developer/common/001-install-packages-opencontrail.sh
./tools/deployment/developer/common/010-deploy-k8s.sh

#Install openstack and heat client
./tools/deployment/developer/common/020-setup-client.sh

#Deploy openstack-helm related charts
export OSH_EXTRA_HELM_ARGS_NOVA="--set images.tags.opencontrail_compute_init=${CONTRAIL_REGISTRY}/contrail-openstack-compute-init:${CONTAINER_TAG}"
export OSH_EXTRA_HELM_ARGS_NEUTRON="--set images.tags.opencontrail_neutron_init=${CONTRAIL_REGISTRY}/contrail-openstack-neutron-init:${CONTAINER_TAG}"

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

#Now deploy opencontrail charts
cd $CHD_PATH
make

#Label nodes with contrail specific labels
kubectl label node opencontrail.org/controller=enabled --all
kubectl label node opencontrail.org/vrouter-kernel=enabled --all

#Give cluster-admin permission for the user to create contrail pods
kubectl replace -f rbac/cluster-admin.yaml

#Populate the contrail-override-values.yaml file
tee /tmp/contrail.yaml << EOF
global:
	images:
		tags:
			cassandra: "${CONTRAIL_REGISTRY}/contrail-external-cassandra:${CONTAINER_TAG}"
			kafka: "${CONTRAIL_REGISTRY}/contrail-external-kafka:${CONTAINER_TAG}"
			zookeeper: "${CONTRAIL_REGISTRY}/contrail-external-zookeeper:${CONTAINER_TAG}"
			config_api: "${CONTRAIL_REGISTRY}/contrail-controller-config-api:${CONTAINER_TAG}"
			config_devicemgr: "${CONTRAIL_REGISTRY}/contrail-controller-config-devicemgr:${CONTAINER_TAG}"
			config_schema_transformer: "${CONTRAIL_REGISTRY}/contrail-controller-config-schema:${CONTAINER_TAG}"
			config_svcmonitor: "${CONTRAIL_REGISTRY}/contrail-controller-config-svcmonitor:${CONTAINER_TAG}"
			contrail_control: "${CONTRAIL_REGISTRY}/contrail-controller-control-control:${CONTAINER_TAG}"
			control_dns: "${CONTRAIL_REGISTRY}/contrail-controller-control-dns:${CONTAINER_TAG}"
			control_named: "${CONTRAIL_REGISTRY}/contrail-controller-control-named:${CONTAINER_TAG}"
			nodemgr: "${CONTRAIL_REGISTRY}/contrail-nodemgr:${CONTAINER_TAG}"
			webui_middleware: "${CONTRAIL_REGISTRY}/contrail-controller-webui-job:${CONTAINER_TAG}"
			webui: "${CONTRAIL_REGISTRY}/contrail-controller-webui-web:${CONTAINER_TAG}"
			analytics_alarm_gen: "${CONTRAIL_REGISTRY}/contrail-analytics-alarm-gen:${CONTAINER_TAG}"
			analytics_api: "${CONTRAIL_REGISTRY}/contrail-analytics-api:${CONTAINER_TAG}"
			analytics_query_engine: "${CONTRAIL_REGISTRY}/contrail-analytics-query-engine:${CONTAINER_TAG}"
			analytics_snmp_collector: "${CONTRAIL_REGISTRY}/contrail-analytics-snmp-collector:${CONTAINER_TAG}"
			contrail_collector: "${CONTRAIL_REGISTRY}/contrail-analytics-collector:${CONTAINER_TAG}"
			contrail_topology: "${CONTRAIL_REGISTRY}/contrail-analytics-topology:${CONTAINER_TAG}"
			build_driver_init: "${CONTRAIL_REGISTRY}/contrail-vrouter-kernel-build-init:${CONTAINER_TAG}"
			vrouter_agent: "${CONTRAIL_REGISTRY}/contrail-vrouter-agent:${CONTAINER_TAG}"
			vrouter_init_kernel: "${CONTRAIL_REGISTRY}/contrail-vrouter-kernel-init:${CONTAINER_TAG}"
			vrouter_dpdk: "${CONTRAIL_REGISTRY}/contrail-vrouter-agent-dpdk:${CONTAINER_TAG}"
			vrouter_init_dpdk: "${CONTRAIL_REGISTRY}/contrail-vrouter-kernel-init-dpdk:${CONTAINER_TAG}"
  contrail_env:
    CONTROLLER_NODES: $intf_ip_address
    LOG_LEVEL: SYS_NOTICE
    CLOUD_ORCHESTRATOR: openstack
    AAA_MODE: cloud-admin
    PHYSICAL_INTERFACE: $physical_intf
EOF

# Install contrail chart
helm install --name contrail ${CHD_PATH}/contrail \
--namespace=contrail --values=/tmp/contrail.yaml

# Deploying heat charts after contrail charts are deployed as they have dependency on contrail charts
cd ${OSH_PATH}
export OSH_EXTRA_HELM_ARGS_HEAT="--set images.tags.opencontrail_heat_init=${CONTRAIL_REGISTRY}/contrail-openstack-heat-init:${CONTAINER_TAG}"

./tools/deployment/developer/nfs/091-heat-opencontrail.sh
