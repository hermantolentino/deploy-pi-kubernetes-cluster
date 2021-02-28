#!/usr/bin/env bash

source .env

IFS=$'\n' # make newlines the only separator, IFS means 'internal field separator'
set -f    # disable globbing

cat nfs-device-name | grep -v '#'
exit 0
for line in $(cat hosts); do
  ipaddress=$(echo $line | cut -d"," -f1)
  role=$(echo $line | cut -d"," -f2)
  echo "line: $ipaddress $role"
  echo "ubuntu@$ipaddress" >> ipaddresses
done
cat ipaddresses
hosts=$(cat ipaddresses)
echo $hosts
parallel-ssh -i -h ipaddresses 'echo "Hello, world"'
