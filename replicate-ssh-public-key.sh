#!/usr/bin/env bash
source ./.env
export SSHPASS=${SSHPASS}
if [ ! -f $(which sshpass) ]; then
  echo 'Please install sshpass and run the script again.\nUbuntu: sudo apt install sshpass -y' && exit 1
fi
cat hosts | while read host || [[ -n $line ]];
do
  echo "Installing SSH public keys in host: $host"
  sshpass -e ssh -y ubuntu@${host} ':> /home/ubuntu/.ssh/authorized_keys'
  sshpass -e ssh-copy-id -i ${KEYFILENAME} ubuntu@${host}
  ssh ubuntu@${host} 'hostname && ip address show eth0 && ip address show wlan0'
done
