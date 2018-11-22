FROM ubuntu:16.04
MAINTAINER Bharath Kassetti

ARG OPENSTACK_BRANCH=R5.0
RUN apt-get update ;\
    apt-get upgrade -y ;\
    apt-get install -y --no-install-recommends \
        git \
        sshpass \
        python-pip ;\
    pip --no-cache-dir install --upgrade pip ;\
    hash -r ;\
    pip --no-cache-dir install --upgrade setuptools ;\
    # use the same ansible verion as upstream
    pip --no-cache-dir install --upgrade "ansible==2.5.5"

ENV BASE_DIR /usr/share
ENV OSH_PATH ${BASE_DIR}/openstack-helm
ENV OSH_INFRA_PATH ${BASE_DIR}/openstack-helm-infra
ENV CHD_PATH ${BASE_DIR}/contrail-helm-deployer

RUN git clone -b ${OPENSTACK_BRANCH} https://github.com/Juniper/openstack-helm.git ${OSH_PATH}; \
    git clone -b ${OPENSTACK_BRANCH} https://github.com/Juniper/openstack-helm-infra.git ${OSH_INFRA_PATH}

COPY contrail ${CHD_PATH}/contrail
COPY helm-toolkit-contrail ${CHD_PATH}/helm-toolkit-contrail
COPY contrail-thirdparty ${CHD_PATH}/contrail-thirdparty
COPY contrail-controller ${CHD_PATH}/contrail-controller
COPY contrail-analytics ${CHD_PATH}/contrail-analytics
COPY contrail-vrouter ${CHD_PATH}/contrail-vrouter
COPY playbooks ${CHD_PATH}/playbooks
COPY docker/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
