#!/usr/bin/env bash

IFS=$'\n' # make newlines the only separator, IFS means 'internal field separator'
set -f    # disable globbing

echo 'Record node IP addresses...'
:> $(pwd)/nodes/worker-node-ip
for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   if [ $role == 'master' ]; then
      echo 'Recording master node IP...'
      echo $ipaddress > $(pwd)/nodes/master-node-ip
      cat $(pwd)/nodes/master-node-ip
   else
      echo 'Recording worker node IP...'
      echo $ipaddress >> $(pwd)/nodes/worker-node-ip
      cat $(pwd)/nodes/worker-node-ip
   fi
done

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   # copy node ip addresses to nodes
   scp -C -r $(pwd)/nodes ubuntu@${ipaddress}:/home/ubuntu/
   echo "Processing host: $ipaddress"
   if [ $role == 'master' ]; then
      echo "Configuring k8s master in $ipaddress..."
      # kube-token
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/01-generate-master-token.sh'
      scp -C ubuntu@${ipaddress}:/home/ubuntu/nodes/kube-token $(pwd)/nodes/master-kube-token
      initfile=$(readlink -f nodes/master-kube-token)
      grep -qxF $initfile $(pwd)/initfiles || echo $initfile >> $(pwd)/initfiles
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/02-nodeconfig-k8s-master-setup.sh'
      # discovery-token
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/03-get-token-ca-cert.sh'
      scp -C ubuntu@${ipaddress}:/home/ubuntu/nodes/discovery-token $(pwd)/nodes/node-discovery-token
      initfile=$(readlink -f nodes/node-discovery-token)
      grep -qxF $initfile $(pwd)/initfiles || echo $initfile >> $(pwd)/initfiles
      echo 'Kubernetes deployments (network, load balancer)...'
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/04-nodeconfig-k8s-master-deploy.sh'
   else
      echo "Configuring k8s worker in $ipaddress..."
      scp -C $(pwd)/nodes/master-kube-token ubuntu@${ipaddress}:/home/ubuntu/nodes/kube-token
      scp -C $(pwd)/nodes/node-discovery-token ubuntu@${ipaddress}:/home/ubuntu/nodes/discovery-token
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/nodeconfig-k8s-worker.sh'
   fi
done
echo 'Finishing cluster set up, will resume script execution after 2 minutes...'
./countdown 00:02:00

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   ssh ubuntu@${ipaddress} 'sudo apt-get update'
   ssh ubuntu@${ipaddress} 'sudo apt-get upgrade --yes'
   ssh ubuntu@${ipaddress} 'sudo reboot'
done
echo 'Finishing up cluster set up, will resume script execution after 2 minutes...'
./countdown 00:02:00

echo 'Check if nodes have rebooted...'
hosts=$(cat ipaddresses)
parallel-ssh -i -H "$hosts" 'echo "Hello, world!" from $(hostname)'

ssh ubuntu@$(cat nodes/master-node-ip) "kubectl get nodes --all-namespaces"
ssh ubuntu@$(cat nodes/master-node-ip) "kubectl get pods --all-namespaces"
ssh ubuntu@$(cat nodes/master-node-ip) "kubectl get services --all-namespaces"
echo 'You can log in to master node.'
