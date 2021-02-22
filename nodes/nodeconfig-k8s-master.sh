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
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
else
    echo "$HOME/.kube/config exists..."
fi
export KUBECONFIG=/etc/kubernetes/admin.conf
# Deploy pod network
# Use calico network driver
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml
kubectl get nodes

# metrics-server service
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
if [ -f /home/ubuntu/nodes/.metallb_installed ]; then
    kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
    touch /home/ubuntu/nodes/.metallb_installed
fi
