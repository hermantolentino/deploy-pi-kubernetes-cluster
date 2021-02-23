#!/usr/bin/env bash

if [ ! -f '/home/ubuntu/nodes/kube-token' ]; then
    echo "Generating token for cluster"
    KUBE_TOKEN=$(sudo kubeadm token generate)
    echo $KUBE_TOKEN > /home/ubuntu/nodes/kube-token
fi
