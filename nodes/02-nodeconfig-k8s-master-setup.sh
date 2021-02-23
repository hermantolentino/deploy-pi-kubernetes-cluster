#!/usr/bin/env bash

source /home/ubuntu/nodes/.env

sudo cp /home/ubuntu/nodes/k8s.conf /etc/sysctl.d/k8s.conf
sudo sysctl --system
KUBE_TOKEN=$(cat /home/ubuntu/nodes/kube-token)
KUBERNETES_VERSION=$(cat /home/ubuntu/nodes/kubernetes-version)
sudo kubeadm config images pull
sudo kubeadm init --token=${KUBE_TOKEN} --kubernetes-version=${KUBERNETES_VERSION} --pod-network-cidr=10.244.0.0/16
if [ ! -f $HOME/.kube/config ]; then
    echo "$HOME/.kube/config does not exist..."
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown -R $USER:$USER $HOME/.kube
else
    echo "$HOME/.kube/config exists..."
fi
export KUBECONFIG=/etc/kubernetes/admin.conf
