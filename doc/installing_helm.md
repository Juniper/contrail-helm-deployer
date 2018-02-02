# Installing helm

1. Downloading Helm

  ```bash
  export HELM_VERSION=v2.7.2
  export TMP_DIR=$(mktemp -d)
  curl -sSL https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -zxv --strip-components=1 -C ${TMP_DIR}
  sudo mv ${TMP_DIR}/helm /usr/local/bin/helm
  rm -rf ${TMP_DIR}

  ```

2. Initializing helm client and tiller server

  ```bash
  helm init
  ```
