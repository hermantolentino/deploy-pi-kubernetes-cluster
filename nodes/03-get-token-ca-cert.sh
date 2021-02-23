#!/usr/bin/env bash
# reference: https://blog.scottlowe.org/2019/07/12/calculating-ca-certificate-hash-for-kubeadm/
DISCOVERY_TOKEN=$(openssl x509 -in /etc/kubernetes/pki/ca.crt -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256 | cut -d' ' -f2)
export DISCOVERY_TOKEN="sha256:$DISCOVERY_TOKEN"
echo ${DISCOVERY_TOKEN} > /home/ubuntu/nodes/discovery-token
