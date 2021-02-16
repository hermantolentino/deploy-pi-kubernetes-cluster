#!/usr/bin/env bash

source /home/ubuntu/nodes/.env

sudo cp /home/ubuntu/nodes/k8s.conf /etc/sysctl.d/k8s.conf
sudo sysctl --system
sudo kubeadm config images pull
KUBE_TOKEN=$(cat /home/ubuntu/nodes/kube-token)
DISCOVERY_TOKEN=$(cat /home/ubuntu/nodes/discovery-token)
sudo kubeadm join ${MASTER_NODE_IP}:6443 --token ${KUBE_TOKEN} --discovery-token-ca-cert-hash ${DISCOVERY_TOKEN}
