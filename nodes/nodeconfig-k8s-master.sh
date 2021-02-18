#!/usr/bin/env bash

source /home/ubuntu/nodes/.env

sudo cp /home/ubuntu/nodes/k8s.conf /etc/sysctl.d/k8s.conf
sudo sysctl --system
KUBE_TOKEN=$(cat /home/ubuntu/nodes/kube-token)
KUBERNETES_VERSION=$(cat /home/ubuntu/nodes/kubernetes-version)
sudo kubeadm config images pull
sudo kubeadm init --token=${KUBE_TOKEN} --kubernetes-version=${KUBERNETES_VERSION} --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo export KUBECONFIG=/etc/kubernetes/admin.conf
# Deploy pod network
# Use calico network driver
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml
kubectl get nodes
HOST_IP=$(ifconfig eth0 | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2)
echo $HOST_IP

# metrics-server service
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
