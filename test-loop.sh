#!/usr/bin/env bash

source .env

IFS=$'\n'       # make newlines the only separator
set -f          # disable globbing
for line in $(cat hosts); do
  ip=$(echo $line | cut -d"," -f1)
  role=$(echo $line | cut -d"," -f2)
  echo "line: $ip $role"
done
