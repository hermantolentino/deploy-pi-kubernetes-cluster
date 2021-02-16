#!/usr/bin/env bash
source ./.env

export SSHPASS=${NEW_SSHPASS}

if [ ! -f $(which sshpass) ]; then
  echo 'Please install sshpass and run the script again.\nUbuntu: sudo apt install sshpass -y' && exit 1
fi

IFS=$'\n'       # make newlines the only separator, IFS means 'internal field separator'
set -f          # disable globbing
for host in $(cat hosts); do
  echo "Logging in for the first time to $host..."
  # Use -oStrictHostKeyChecking=no to automatically accept host keys when
  #   logging in for the first time...
  sshpass -e ssh -oStrictHostKeyChecking=no ubuntu@${host} 'uptime'
done

WORKER_COUNTER=0
for host in $(cat hosts); do
   echo "Processing host, stage 1: $host"
   echo "Setting hostname for host: $host"
   if [ $host == $MASTER_NODE_IP ]; then
      sshpass -e ssh ubuntu@${host} 'echo "k8s-master" > /home/ubuntu/nodes/hostname'
      sshpass -e ssh ubuntu@${host} 'sudo cp /home/ubuntu/nodes/hostname /etc/hostname'
   else
      ((WORKER_COUNTER++))
      printf -v WORKER '%03d' $WORKER_COUNTER
      sshpass -e ssh ubuntu@${host} "echo 'k8s-master-$WORKER' > /home/ubuntu/nodes/hostname"
      sshpass -e ssh ubuntu@${host} 'sudo cp /home/ubuntu/nodes/hostname /etc/hostname'
   fi
done

for host in $(cat hosts); do
   echo "Installing SSH public keys in host: $host"
   sshpass -e ssh -y ubuntu@${host} ':> /home/ubuntu/.ssh/authorized_keys'
   sshpass -e ssh-copy-id -i ${KEYFILENAME} ubuntu@${host}
   echo "Copying nodes folder and .env to $host..."
   sshpass -e ssh ubuntu@${host} 'mkdir -p /home/ubuntu/nodes'
   sshpass -e scp -r $(pwd)/nodes ubuntu@${host}:/home/ubuntu/
   sshpass -e scp $(pwd)/.env ubuntu@${host}:/home/ubuntu/nodes/.env
   sshpass -e ssh ubuntu@${host} 'ls -la /home/ubuntu/nodes'
done

for host in $(cat hosts); do
   echo "Installing packages to $host..."
   sshpass -e ssh ubuntu@${host} '/home/ubuntu/nodes/install-node-packages.sh'
done

for host in $(cat hosts); do
   echo "Configuring network in $host..."
   sshpass -e ssh ubuntu@${host} 'cd /home/ubuntu/nodes/ && ./create-network-config.py && cat ./50-cloud-init.yaml'
   sshpass -e ssh ubuntu@${host} 'sudo cp /home/ubuntu/nodes/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml'
   echo "Configuring docker in $host..."
   sshpass -e ssh ubuntu@${host} '/home/ubuntu/nodes/nodeconfig-docker.sh'
done

for host in $(cat hosts); do
   echo "Rebooting (2): $host"
   sshpass -e ssh ubuntu@${host} 'sudo reboot'
done
sleep 3m

for host in $(cat hosts); do
   echo "Processing host, stage 2: $host"
   if [ $host == $MASTER_NODE_IP ]; then
      echo "Configuring k8s master in $host..."
      sshpass -e ssh ubuntu@${host} '/home/ubuntu/nodes/generate-master-token.sh'
      scp -C ubuntu@${host}:/home/ubuntu/nodes/kube-token nodes/master-kube-token
      sshpass -e ssh ubuntu@${host} '/home/ubuntu/nodes/nodeconfig-k8s-master.sh'
      sshpass -e ssh ubuntu@${host} '/home/ubuntu/nodes/get-token-ca-cert.sh'
      scp -C ubuntu@${host}:/home/ubuntu/nodes/discovery-token nodes/node-discovery-token
   else
      echo "Configuring k8s worker in $host..."
      sshpass -e scp -C nodes/master-kube-token ubuntu@${host}:/home/ubuntu/nodes/kube-token
      sshpass -e scp -C nodes/node-discovery-token ubuntu@${host}:/home/ubuntu/nodes/discovery-token
      sshpass -e ssh ubuntu@${host} '/home/ubuntu/nodes/nodeconfig-k8s-worker.sh'
   fi
done
