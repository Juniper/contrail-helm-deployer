# Quickstart steps for k8s Installation

1. Install kubernetes binaries on all nodes in your cluster

  ```bash
  sudo apt-get install \
      apt-transport-https \
      ca-certificates \
      curl -y

  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  sudo bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
  deb http://apt.kubernetes.io/ kubernetes-xenial main
  EOF'

  sudo apt-get update -y
  sudo apt-get install -y kubectl=1.8.3-00
  sudo apt-get install -y kubelet=1.8.3-00
  sudo apt-get install -y kubeadm=1.8.3-00
  sudo apt-get install -y docker.io

  # Disable all swaps on all nodes
  swapoff -a
  ```


2. Bring up k8s master on a single node by running the below command.

  ```bash

  # Initialize a kubernetes master node
  kubeadm init --kubernetes-version v1.8.3

  # Copy the right conf file for kubectl to detect
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # Install CNI
  kubectl apply -f https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml
  ```

3. Joining the rest of nodes as slave to the k8s cluster

  ```bash
  # kubeadm init would have returned a kubeadm join command at end of stdout, run that command on rest of the nodes

  # Sample kubeadm join command
  sudo kubeadm join --token fd554a.97d239c2234d0de352 10.87.65.241:6443
  ```

4. Execute below command on all master node to verify that all nodes in ready state

  ```bash
  root@b7s32:~# kubectl get nodes
  NAME      STATUS    ROLES     AGE       VERSION
  b7s32     Ready     master    1h        v1.8.3
  b7s33     Ready     <none>    1h        v1.8.3
  b7s34     Ready     <none>    1h        v1.8.3
  b7s35     Ready     <none>    1h        v1.8.3
  b7s36     Ready     <none>    1h        v1.8.3
  ```

5. If you would like to bring up openstack/contrail pods on master node, then please execute the below command

  ```bash
  kubectl taint nodes --all node-role.kubernetes.io/master-
  ```

6. Adding upstream servers for kubernetes to resolve names which does not match the k8s domain names

  ```bash
  cat <<EOF | kubectl create -f -
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: kube-dns
    namespace: kube-system
  data:
    upstreamNameservers: |
      ["8.8.8.8", "8.8.4.4"]
  EOF
  ```
