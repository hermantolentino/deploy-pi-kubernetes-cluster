#!/usr/bin/env bash
source ./.env

export SSHPASS=${NEW_SSHPASS}

if [ ! -f $(which sshpass) ]; then
  echo 'Please install sshpass and run the script again.\nUbuntu: sudo apt install sshpass -y' && exit 1
fi

IFS=$'\n'       # make newlines the only separator, IFS means 'internal field separator'
set -f          # disable globbing
for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   if [ $role == 'master']; then
      echo $ipaddress > $(pwd)/nodes/master-node-ip
   fi
   echo "Logging in for the first time to $ipaddress..."
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   # Remove host ip address from known_hosts in set up machine
   ssh-keygen -f "/home/${USERNAME}/.ssh/known_hosts" -R $ipaddress
   # Use -oStrictHostKeyChecking=no to automatically accept host keys when
   #   (assume) logging in for the first time...
   sshpass -e ssh -oStrictHostKeyChecking=no ubuntu@${ipaddress} 'uptime'
done

WORKER_COUNTER=0
MASTER_COUNTER=0
for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)

   echo "Processing host, stage 1: $ipaddress"
   echo "Setting hostname for host: $ipaddress"
   sshpass -e ssh ubuntu@${ipaddress} "touch /home/ubuntu/nodes/hostname"
   if [ $role == 'master' ]; then
      ((MASTER_COUNTER++))
      printf -v MASTER '%03d' $MASTER_COUNTER
      sshpass -e ssh ubuntu@${ipaddress} "echo 'k8s-master-$MASTER' > /home/ubuntu/nodes/hostname"
      sshpass -e ssh ubuntu@${ipaddress} "sudo hostname k8s-master-$MASTER"
      sshpass -e ssh ubuntu@${ipaddress} 'sudo cp /home/ubuntu/nodes/hostname /etc/hostname'
   else
      ((WORKER_COUNTER++))
      printf -v WORKER '%03d' $WORKER_COUNTER
      sshpass -e ssh ubuntu@${ipaddress} "echo 'k8s-worker-$WORKER' > /home/ubuntu/nodes/hostname"
      sshpass -e ssh ubuntu@${ipaddress} "sudo hostname k8s-worker-$WORKER"
      sshpass -e ssh ubuntu@${ipaddress} 'sudo cp /home/ubuntu/nodes/hostname /etc/hostname'
   fi
done

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   echo "Rebooting: $ipaddress"
   sshpass -e ssh ubuntu@${ipaddress} 'sudo reboot'
done
sleep 3m

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   echo "Installing packages to $ipaddress..."
   sshpass -e ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/install-node-packages.sh'
done

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   echo "Configuring network in $ipaddress..."
   sshpass -e ssh ubuntu@${ipaddress} 'cd /home/ubuntu/nodes/ && ./create-network-config.py && cat ./50-cloud-init.yaml'
   sshpass -e ssh ubuntu@${ipaddress} 'sudo cp /home/ubuntu/nodes/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml'
   echo "Configuring docker in $ipaddress..."
   sshpass -e ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/nodeconfig-docker.sh'
done

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   echo "Rebooting: $ipaddress"
   sshpass -e ssh ubuntu@${ipaddress} 'sudo reboot'
   echo 'Wait for 3 minutes before running next configuration script...'
done
sleep 3m
