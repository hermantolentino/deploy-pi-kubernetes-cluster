#!/usr/bin/env bash

source ./.env

if [ ! -f ./.password_changed ]; then
   echo 'Host passwords have *not* been changed...'
   export SSHPASS=${OLD_SSHPASS}
else
   echo 'Host passwords have been changed...'
   export SSHPASS=${NEW_SSHPASS}
   exit 0
fi
if [ ! -f $(which sshpass) ]; then
  echo 'Please install sshpass and run the script again.\nUbuntu: sudo apt install sshpass -y' && exit 1
fi

IFS=$'\n'       # make newlines the only separator, IFS means 'internal field separator'
set -f          # disable globbing
for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   echo "Logging in for the first time to $ipaddress..."
   # Remove host ip address from known_hosts in set up machine
   ssh-keygen -f "/home/${USERNAME}/.ssh/known_hosts" -R $ipaddress
   # Use -oStrictHostKeyChecking=no to automatically accept host keys when
   #   (assume) logging in for the first time...
   $(pwd)/password-change-expect.ex $HOST_USERNAME $OLD_SSHPASS $ipaddress $NEW_SSHPASS
   #sshpass -e ssh -t -t -oStrictHostKeyChecking=no ubuntu@${ipaddress} "echo 'ubuntu:${NEW_SSHPASS}' | sudo chpasswd"
done

if [ ! -f ./.password_changed ]; then
   touch ./.password_changed
   initfile=$(readlink -f $(pwd)/.password_changed)
   grep -qxF $initfile $(pwd)/initfiles || echo $initfile >> $(pwd)/initfiles
fi

export SSHPASS=${NEW_SSHPASS}

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   sshpass -e ssh ubuntu@${ipaddress} 'uptime'
   echo "Rebooting Raspberry Pi  @$ipaddress"
   sshpass -e ssh ubuntu@${ipaddress} 'sudo reboot'
done
echo 'Password change completed, log back in after 3 minutes...'
sleep 3m
