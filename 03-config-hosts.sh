#!/usr/bin/env bash

source .env

if [ ! -f $(which sshpass) ]; then
  echo 'Please install sshpass and run the script again.\nUbuntu: sudo apt install sshpass -y' && exit 1
fi

if [ ! -f $(which parallel-ssh) ]; then
  echo 'Please install parallel-ssh and run the script again.\nUbuntu: sudo apt install parallel-ssh -y' && exit 1
fi

IFS=$'\n'  # make newlines the only separator, IFS means 'internal field separator'
set -f     # disable globbing

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   if [ $role == 'master' ]; then
      echo $ipaddress > $(pwd)/nodes/master-node-ip
   fi
   echo "Logging in for the first time to $ipaddress..."
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   # Remove host ip address from known_hosts in set up machine
   ssh-keygen -f "/home/${USERNAME}/.ssh/known_hosts" -R $ipaddress
   ssh -oStrictHostKeyChecking=no ubuntu@${ipaddress} 'uptime'
done

WORKER_COUNTER=0
MASTER_COUNTER=0
:> nodes/hostnames
for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)

   echo "Processing host, stage 1: $ipaddress"
   echo "Setting hostname for host: $ipaddress"
   ssh ubuntu@${ipaddress} "touch /home/ubuntu/nodes/hostname"
   if [ $role == 'master' ]; then
      ((MASTER_COUNTER++))
      printf -v MASTER '%03d' $MASTER_COUNTER
      ssh ubuntu@${ipaddress} "echo 'k8s-master-$MASTER' > /home/ubuntu/nodes/hostname"
      ssh ubuntu@${ipaddress} "sudo hostname k8s-master-$MASTER"
      ssh ubuntu@${ipaddress} 'sudo cp /home/ubuntu/nodes/hostname /etc/hostname'
   else
      ((WORKER_COUNTER++))
      printf -v WORKER '%03d' $WORKER_COUNTER
      ssh ubuntu@${ipaddress} "echo 'k8s-worker-$WORKER' > /home/ubuntu/nodes/hostname"
      ssh ubuntu@${ipaddress} "sudo hostname k8s-worker-$WORKER"
      ssh ubuntu@${ipaddress} 'sudo cp /home/ubuntu/nodes/hostname /etc/hostname'
   fi
   ssh ubuntu@${ipaddress} "echo 'hostname:' && cat /etc/hostname"
   pi_hostname=$(ssh ubuntu@${ipaddress} 'cat /etc/hostname')
   echo "$ipaddress $pi_hostname" >> nodes/hostnames
done
echo 'Hostnames:'
cat $(pwd)/nodes/hostnames

echo 'Rebooting nodes...'
for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   echo "Rebooting: $ipaddress"
   ssh ubuntu@${ipaddress} 'sudo reboot'
done

echo 'Hostname update completed, will resume script execution after 2 minutes...'
./countdown 00:02:00

echo 'Check if nodes have rebooted...'
hosts=$(cat ipaddresses)
parallel-ssh -i -H "$hosts" 'echo "Hello, world!" from $(hostname)'

echo 'Setting up required packages...'
parallel-ssh -i -t 0 -H "$hosts" '/home/ubuntu/nodes/install-node-packages.sh'
parallel-ssh -i -t 0 -H "$hosts" '/home/ubuntu/nodes/nodeconfig-docker.sh'

echo 'Rebooting nodes...'
for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   echo "Rebooting: $ipaddress"
   ssh ubuntu@${ipaddress} 'sudo reboot'
done
echo 'Node configuration completed, continue with cluster set up after 2 minutes...'
./countdown 00:02:00

echo 'Check if nodes have rebooted...'
hosts=$(cat ipaddresses)
parallel-ssh -i -H "$hosts" 'echo "Hello, world!" from $(hostname)'
