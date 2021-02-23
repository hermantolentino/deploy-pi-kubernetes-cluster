#!/usr/bin/env bash

# Deploy pod network
# Use calico network driver
#curl -sSL https://docs.projectcalico.org/manifests/calico.yaml -O
#kubectl apply -f calico.yaml

# Use flannel as network driver
curl -sSL https://raw.githubusercontent.com/coreos/flannel/v0.12.0/Documentation/kube-flannel.yml | kubectl apply -f -

# metrics-server service
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
if [ -f /home/ubuntu/nodes/.metallb_installed ]; then
    kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
    touch /home/ubuntu/nodes/.metallb_installed
fi

