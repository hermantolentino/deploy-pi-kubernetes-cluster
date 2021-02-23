#!/usr/bin/env bash

source .env
export SSHPASS=${NEW_SSHPASS}

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   if [ $role == 'master' ]; then
      echo 'Recording master node IP...'
      echo $ipaddress > $(pwd)/nodes/master-node-ip
      cat $(pwd)/nodes/master-node-ip
   fi
   scp -C nodes/* ubuntu@${ipaddress}:/home/ubuntu/nodes/
   echo "Processing host, stage 2: $ipaddress"
   if [ $role == 'master' ]; then
      echo "Configuring k8s master in $ipaddress..."
      # kube-token
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/01-generate-master-token.sh'
      scp -C ubuntu@${ipaddress}:/home/ubuntu/nodes/kube-token nodes/master-kube-token
      initfile=$(readlink -f nodes/master-kube-token)
      grep -qxF $initfile $(pwd)/initfiles || echo $initfile >> $(pwd)/initfiles
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/02-nodeconfig-k8s-master-setup.sh'
      ssh ubuntu@${ipaddress} 'curl -sSL https://raw.githubusercontent.com/coreos/flannel/v0.12.0/Documentation/kube-flannel.yml | kubectl apply -f -'
      # discovery-token
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/03-get-token-ca-cert.sh'
      scp -C ubuntu@${ipaddress}:/home/ubuntu/nodes/discovery-token nodes/node-discovery-token
      initfile=$(readlink -f nodes/node-discovery-token)
      grep -qxF $initfile $(pwd)/initfiles || echo $initfile >> $(pwd)/initfiles
      echo 'Kubernetes deployments (network, load balancer)...'
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/04-nodeconfig-k8s-master-deploy.sh'
   else
      echo "Configuring k8s worker in $ipaddress..."
      scp -C nodes/master-kube-token ubuntu@${ipaddress}:/home/ubuntu/nodes/kube-token
      scp -C nodes/node-discovery-token ubuntu@${ipaddress}:/home/ubuntu/nodes/discovery-token
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/nodeconfig-k8s-worker.sh'
   fi
done
sleep 3m
ssh ubuntu@$(cat nodes/master-node-ip) "kubectl get nodes"
ssh ubuntu@$(cat nodes/master-node-ip) "kubectl get pods"
ssh ubuntu@$(cat nodes/master-node-ip) "kubectl get services"
