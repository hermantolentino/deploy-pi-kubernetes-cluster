#!/usr/bin/env bash

IFS=$'\n' # make newlines the only separator, IFS means 'internal field separator'
set -f    # disable globbing

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   ssh ubuntu@${ipaddress} 'sudo apt-get update'
   ssh ubuntu@${ipaddress} 'sudo apt-get upgrade --yes'
   ssh ubuntu@${ipaddress} 'sudo reboot'
done
echo 'Rebooting cluster, check back after 2 minutes...'
./countdown 00:02:00
