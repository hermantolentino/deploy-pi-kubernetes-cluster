#!/usr/bin/env bash

./00-initialize-setup-machine.sh
./01-change-host-passwords.sh
./02b-upload-ssh-public-keys.sh
./03-config-hosts.sh
./04-configure-cluster.sh
./05-configure-cluster-nfs.sh
