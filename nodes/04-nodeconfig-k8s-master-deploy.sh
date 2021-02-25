#!/usr/bin/env bash

# Deploy pod network
# Use calico as CNI provider
cd /home/ubuntu/nodes && curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f /home/ubuntu/nodes/calico.yaml

# load balancer
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
if [ -f /home/ubuntu/nodes/metallb_secretkey ]; then
    echo $(openssl rand -base64 128) > /home/ubuntu/nodes/metallb_secretkey
fi
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(cat /home/ubuntu/nodes/metallb_secretkey)"
