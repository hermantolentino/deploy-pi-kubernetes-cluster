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
   sshpass -e scp -C nodes/* ubuntu@${ipaddress}:/home/ubuntu/nodes/
   echo "Processing host, stage 2: $ipaddress"
   if [ $role == 'master' ]; then
      echo "Configuring k8s master in $ipaddress..."
      sshpass -e ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/generate-master-token.sh'
      sshpass -e scp -C ubuntu@${ipaddress}:/home/ubuntu/nodes/kube-token nodes/master-kube-token
      initfile=$(readlink -f nodes/master-kube-token)
      grep -qxF $initfile $(pwd)/initfiles || echo $initfile >> $(pwd)/initfiles
      sshpass -e ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/nodeconfig-k8s-master.sh'
      sshpass -e ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/get-token-ca-cert.sh'
      sshpass -e scp -C ubuntu@${ipaddress}:/home/ubuntu/nodes/discovery-token nodes/node-discovery-token
      initfile=$(readlink -f nodes/node-discovery-token)
      grep -qxF $initfile $(pwd)/initfiles || echo $initfile >> $(pwd)/initfiles
   else
      echo "Configuring k8s worker in $ipaddress..."
      sshpass -e scp -C nodes/master-kube-token ubuntu@${ipaddress}:/home/ubuntu/nodes/kube-token
      sshpass -e scp -C nodes/node-discovery-token ubuntu@${ipaddress}:/home/ubuntu/nodes/discovery-token
      sshpass -e ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/nodeconfig-k8s-worker.sh'
   fi
done
sleep 3m
sshpass -e ssh ubuntu@$(cat nodes/master-node-ip) "kubectl get nodes"
