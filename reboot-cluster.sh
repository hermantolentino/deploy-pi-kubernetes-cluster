#!/usr/bin/env bash

IFS=$'\n' # make newlines the only separator, IFS means 'internal field separator'
set -f    # disable globbing

echo 'Rebooting cluster, check back after 2 minutes...'
for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   ssh ubuntu@${ipaddress} 'sudo reboot'
done
./countdown 00:02:00
