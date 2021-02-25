#!/usr/bin/env bash

# Deploy pod network
# Use calico as CNI provider
cd /home/ubuntu/nodes && curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f /home/ubuntu/nodes/calico.yaml

# Use flannel as CNI provider
#curl -sSL https://raw.githubusercontent.com/coreos/flannel/v0.12.0/Documentation/kube-flannel.yml | kubectl apply -f -

# metrics-server and dashboard service
#kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
#kubectl apply -f /home/ubuntu/nodes/metrics-server-components.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml

# load balancer
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
if [ -f /home/ubuntu/nodes/metallb_secretkey ]; then
    echo $(openssl rand -base64 128) > /home/ubuntu/nodes/metallb_secretkey
fi
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(cat /home/ubuntu/nodes/metallb_secretkey)"
