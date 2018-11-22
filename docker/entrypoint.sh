#!/bin/bash
if [[ ! -e /inventory.yaml ]]; then
  echo "Inventory file is not present"
  exit 0
fi
# run ansible playbooks
ansible-playbook -i /inventory.yaml -e clone_openstack=no ${CHD_PATH}/playbooks/configure_nodes.yaml
ansible-playbook -i /inventory.yaml ${CHD_PATH}/playbooks/install_k8s.yaml
ansible-playbook -i /inventory.yaml ${CHD_PATH}/playbooks/install_openstack.yaml
ansible-playbook -i /inventory.yaml ${CHD_PATH}/playbooks/install_contrail.yaml
