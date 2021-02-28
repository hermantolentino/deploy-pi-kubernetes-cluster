#!/usr/bin/env bash

echo 'Updating node packages...'
hosts=$(cat ipaddresses)
parallel-ssh -i -t 0 -H "$hosts" 'export DEBIAN_FRONTEND=noninteractive && sudo apt-get update && sudo apt-get --with-new-pkgs upgrade --yes && sudo apt-get autoremove -y'

IFS=$'\n'  # make newlines the only separator, IFS means 'internal field separator'
set -f     # disable globbing

echo 'Rebooting nodes...'
for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   echo "Rebooting: $ipaddress"
   ssh ubuntu@${ipaddress} 'sudo reboot'
done

echo 'Node update completed, check back after 2 minutes...'
./countdown 00:02:00
