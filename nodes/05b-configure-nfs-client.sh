#!/usr/bin/env bash

export DEBIAN_FRONTEND='noninteractive'

cd /home/ubuntu/nodes

echo 'Installing NFS packages...'
sudo apt-get install nfs-common cifs-utils libnfs-utils -y

echo 'Mounting NFS mount point...'
sudo mkdir -p /mnt/nfs
sudo mount $(cat master-node-ip):/srv/nfs /mnt/nfs

echo 'Setting up /etc/fstab...'
echo "$(cat master-node-ip):/srv/nfs /mnt/nfs  nfs  defaults 0  0" > nfs-fstab-worker
fstab=$(cat nfs-fstab-worker)
echo "nfs-fstab: ${fstab}"
sudo cp /etc/fstab orig-fstab && sudo chown ubuntu:ubuntu orig-fstab
(grep "/srv/nfs" orig-fstab && echo 'NFS share exists in /etc/fstab') || (echo $fstab | sudo tee -a orig-fstab && echo 'NFS share added to /etc/fstab')
sudo cp orig-fstab /etc/fstab
cat /etc/fstab

echo 'Testing NFS mount...'
match=$(mount | grep -oh "/srv/nfs" || echo 'Device not mounted')
echo "match: $match"
if [ "$match" == '/srv/nfs' ]; then
  cat /mnt/nfs/nfs-test
  echo $(df -ha | grep /srv/nfs)
fi
