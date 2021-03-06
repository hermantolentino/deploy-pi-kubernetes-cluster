#!/usr/bin/env bash

source ./.env

IFS=$'\n'       # make newlines the only separator, IFS means 'internal field separator'
set -f          # disable globbing

if [ ! -f $(which sshpass) ]; then
   echo 'Please install sshpass and run the script again.\nUbuntu: sudo apt install sshpass -y' && exit 1
else
   echo 'sshpass is installed'
fi
if [ ! -f $(which parallel-ssh) ]; then
   echo 'Please install parallel-ssh and run the script again.\nUbuntu: sudo apt install parallel-ssh -y' && exit 1
else
   echo 'parallel-ssh is installed.'
fi

if [ ! -f ./.password_changed ]; then
   echo 'Host passwords have *not* been changed.'
   export SSHPASS=${OLD_SSHPASS}
else
   echo 'Host passwords have been changed...'
   export SSHPASS=${NEW_SSHPASS}
   exit 0
fi

:> ipaddresses
for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   echo "Logging in for the first time to $ipaddress..."
   # Remove host ip address from known_hosts in set up machine
   ssh-keygen -f "/home/${USERNAME}/.ssh/known_hosts" -R $ipaddress
   # Use -oStrictHostKeyChecking=no to automatically accept host keys when
   #   (assume) logging in for the first time...
   $(pwd)/password-change-expect.exp $HOST_USERNAME $OLD_SSHPASS $ipaddress $NEW_SSHPASS
   echo "ubuntu@$ipaddress" >> ipaddresses
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
echo 'Password change completed, continue with next script after 2 minutes...'
./countdown 00:02:00
