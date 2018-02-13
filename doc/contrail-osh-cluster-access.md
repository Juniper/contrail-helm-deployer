# How to access OpenContrail OpenStack Helm Cluster?


Once OpenStack & OpenContrail Helm cluster provisioning is completed please follow below steps to access OpenStack & Contrail WebUI and prepare openstack client for CLI

### Installation of OpenStack Client

First step is installation of Openstack client "CLI tool", you can install OpenStack CLI on master Ubuntu host using follwong steps:

```
apt install python-dev python-pip -y
pip install --upgrade pip
pip install python-openstackclient    OR
apt-get install python-openstackclient
````
Note: In case facing issue in installing "python-dev" package follow these steps:

```
Add following repo to source "/etc/apt/sources.list"
deb http://archive.ubuntu.com/ubuntu/ xenial-updates main universe multiverse
apt-get update
apt-get install python-dev
```

### Create openstackrc file and test OpenStack Client

* To start using OpenStack CLI you need openstackrc file and you can create one using following step:

```
cat > /root/openstackrc << EOF
export OS_USERNAME=admin
export OS_PASSWORD=password
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://keystone-api.openstack:35357/v3
# The following lines can be omitted
#export OS_TENANT_ID=tenantIDString
#export OS_REGION_NAME=regionName
export OS_IDENTITY_API_VERSION=3
export OS_USER_DOMAIN_NAME=${OS_USER_DOMAIN_NAME:-"Default"}
export OS_PROJECT_DOMAIN_NAME=${OS_PROJECT_DOMAIN_NAME:-"Default"}
EOF
```

* Test openstack client using following steps:
  ```
  source openstackrc
  openstack server list
  openstack stack list
  openstack --help
  ```

### Accessing Contrail WebUI

Contrail GUI accessable via port 8143 and you can use following link to access. Please replace IP 10.13.82.233 with the host IP where contrail-webui POD is running. In below example contrail-webui pod is running on 10.13.82.233 host.

* Default username/passsword: admin/password
```
Access Contrail GUI at port 8143
https://10.13.82.233:8143
```


### Accessing OpenStack Horizon

Openstack GUI servcie is exposed via k8s servcie using node port and defulat port used is 31000 and you can check NodePort used for Openstack webui POD via following command. In below output port 31000 is used and you can access GUI using following URL.

* Openstack GUI username/password: admin/password

```
1. kubectl get svc -n openstack | grep horizon-int
horizon-int           NodePort    10.99.150.28     <none>        80:31000/TCP         4d

2. http://10.13.82.233:31000/auth/login/?next=/
```

### Acessing Virtual Machine Console via Horizon

* To access VM console you have to add nova novncproxy FQDN in "/etc/hosts" file. Please add host-ip where "osh-ingress" POD is running. In below example ingree pod is running on host with IP 10.13.82.233. Here are instructions for updating "/etc/hosts entries for MAC-OS.

```bash
/private/etc/hosts                                                                                                   
127.0.0.1	localhost
255.255.255.255	broadcasthost
::1             localhost
10.13.82.233 nova-novncproxy.openstack.svc.cluster.local
```

Tip: If you don't want to make changes in "/etc/hosts" you can repalce "nova-novncproxy.openstack.svc.cluster.local" part in URL with the IP address where OSH Ingress POD is running.

### Refernces:

* https://docs.openstack.org/newton/install-guide-ubuntu/keystone-openrc.html
* https://docs.openstack.org/newton/user-guide/common/cli-install-openstack-command-line-clients.html
* https://docs.openstack.org/openstack-helm/latest/install/ext-dns-fqdn.html

