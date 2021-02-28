#!/usr/bin/env bash

export DEBIAN_FRONTEND='noninteractive'

echo 'Installing NFS packages...'
sudo apt-get install nfs-common nfs-kernel-server -y

echo 'Setting up /etc/fstab...'
cd /home/ubuntu/nodes
fstab=$(cat nfs-fstab)
echo "nfs-fstab: ${fstab}"
sudo cp /etc/fstab orig-fstab && sudo chown ubuntu:ubuntu orig-fstab
grep -qxF "$fstab" orig-fstab || echo $fstab | sudo tee -a orig-fstab
sudo cp orig-fstab /etc/fstab
cat /etc/fstab

echo 'Setting up /etc/exports...'
exports=$(cat nfs-exports)
echo "nfs-exports: ${exports}"
sudo cp /etc/exports orig-exports && sudo chown ubuntu:ubuntu orig-exports
grep -qxF "$exports" orig-exports || echo $exports | sudo tee -a orig-exports
sudo cp orig-exports /etc/exports
cat /etc/exports

echo 'Enabling NFS server...'
sudo systemctl enable rpcbind.service
sudo systemctl enable nfs-server.service
sudo systemctl start rpcbind.service
sudo systemctl start nfs-server.service
sudo systemctl start nfs-server.service
sudo mkdir -p /srv/nfs
sudo chmod a+w -R /srv/nfs
sudo systemctl restart nfs-server.service

echo 'Testing NFS mount...'
match=$(mount | grep -oh "/dev/sda" || echo 'Device not mounted')
echo "match: $match"
if [ "$match" == '/dev/sda' ]; then
  echo "Can you see this?" > /srv/nfs/nfs-test
  echo $(df -ha | grep /dev/sda)
fi
