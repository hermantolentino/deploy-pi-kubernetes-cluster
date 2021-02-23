#!/usr/bin/env bash

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common net-tools

# Docker packages
PKG_OK=0
until [ $PKG_OK == 1 ]; do
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    echo "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    PKG_OK=$(dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -c "ok installed")
done

# Kubernetes packages
PKG_OK=0
until [ $PKG_OK == 1 ]; do
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    PKG_OK=$(dpkg-query -W -f='${Status}' kubelet 2>/dev/null | grep -c "ok installed")
done
sudo apt-mark hold kubelet kubeadm kubectl

# Python packages
sudo apt-get install -y python3 python3-pip
sudo apt-get autoremove -y
sudo pip3 install pyyaml python-dotenv netifaces

# Helm install
# define what Helm version and where to install:
export HELM_VERSION=v3.0.2
export HELM_INSTALL_DIR=/usr/local/bin
# download the binary and get into place:
wget https://get.helm.sh/helm-$HELM_VERSION-linux-arm64.tar.gz
tar xvzf helm-$HELM_VERSION-linux-arm64.tar.gz
sudo mv linux-arm64/helm $HELM_INSTALL_DIR/helm
# clean up:
rm -rf linux-arm64 && rm helm-$HELM_VERSION-linux-arm64.tar.gz
helm version

# autoremove
sudo apt-get autoremove -y
