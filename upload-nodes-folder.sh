#!/usr/bin/env bash

IFS=$'\n' # make newlines the only separator, IFS means 'internal field separator'
set -f    # disable globbing

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
   scp -C -r $(pwd)/nodes ubuntu@${ipaddress}:/home/ubuntu/
done
