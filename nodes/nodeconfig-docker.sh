#!/usr/bin/env bash

echo 'Configuring docker...'
uname -a
echo "hostname: $(hostname)"
echo 'authorized_keys:'
cat /home/ubuntu/.ssh/authorized_keys
sudo -- sh -c "cat /dev/null > /boot/firmware/cmdline.txt"
sudo -- sh -c "cat /home/ubuntu/nodes/cgroups-cmdline.txt > /boot/firmware/cmdline.txt"
sudo -- sh -c "cat /home/ubuntu/nodes/daemon.json > /etc/docker/daemon.json"
sudo docker info
sudo usermod -aG docker ubuntu
echo 'Docker configuration complete...'
