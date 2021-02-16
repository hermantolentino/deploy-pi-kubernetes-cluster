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
for host in $(cat hosts); do
  echo "Logging in for the first time to $host..."
  # Use -oStrictHostKeyChecking=no to automatically accept host keys when
  #   logging in for the first time...
  sshpass -e ssh -oStrictHostKeyChecking=no ubuntu@${host} 'uptime'
  sshpass -e ssh ubuntu@${host} "echo 'ubuntu:${NEW_SSHPASS}' | sudo chpasswd"
done

if [ ! -f ./.password_changed ]; then
   touch ./.password_changed
fi

export SSHPASS=${NEW_SSHPASS}

for host in $(cat hosts); do
   echo "Rebooting (1): $host"
   sshpass -e ssh ubuntu@${host} 'sudo reboot'
done
echo 'Password change completed, log back in after 5 minutes...'
