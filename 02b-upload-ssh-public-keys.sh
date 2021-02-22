#!/usr/bin/env bash

source .env
export SSHPASS=${NEW_SSHPASS}

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)

   echo "Installing SSH public keys in host: $ipaddress"
   sshpass -e ssh -y ubuntu@${ipaddress} 'touch /home/ubuntu/.ssh/authorized_keys'
   #sshpass -e ssh -y ubuntu@${ipaddress} ':> /home/ubuntu/.ssh/authorized_keys'
   sshpass -e ssh-copy-id -i ${KEYFILENAME} ubuntu@${ipaddress}
   echo "Copying nodes folder and .env to $ipaddress..."
   sshpass -e ssh ubuntu@${ipaddress} 'mkdir -p /home/ubuntu/nodes'
   sshpass -e scp -r $(pwd)/nodes ubuntu@${ipaddress}:/home/ubuntu/
   sshpass -e scp $(pwd)/.env ubuntu@${ipaddress}:/home/ubuntu/nodes/.env
   sshpass -e ssh ubuntu@${ipaddress} 'ls -la /home/ubuntu/nodes'
done
