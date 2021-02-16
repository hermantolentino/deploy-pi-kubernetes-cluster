#!/usr/bin/env bash

source .env

IFS=$'\n'       # make newlines the only separator
set -f          # disable globbing
for host in $(cat hosts); do
  echo "line: $host"
done
