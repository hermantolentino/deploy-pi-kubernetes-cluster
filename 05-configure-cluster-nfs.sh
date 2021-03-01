#!/usr/bin/env bash

IFS=$'\n' # make newlines the only separator, IFS means 'internal field separator'
set -f    # disable globbing

if [ ! -f $(which ipcalc) ]; then
   echo 'Please install ipcalc: sudo apt-get ipcalc -y' && exit 1
fi
echo 'Setting up cluster NFS...'
for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   echo "===================== $role ====================="
   if [ $role == 'master' ]; then
      echo "-----> Processing /etc/fstab"
      device_item=$(cat $(pwd)/nodes/nfs-device-name | (grep -v '#' || grep '/dev/sda') || echo 'No device found')
      device=$(echo $device_item | cut -d' ' -f1)
      uuid=$(echo $device_item | cut -d' ' -f2)
      if [ $device_item == 'No device found' ]; then
         echo 'No device to mount for NFS.' && exit 0
      else
         echo "Device name: $device"
         echo "Device UUID: $uuid"

      fi
      rm $(pwd)/nodes/nfs-fstab && cp $(pwd)/nodes/nfs-fstab-template $(pwd)/nodes/nfs-fstab
      netmask=$(ssh ubuntu@${ipaddress} "ifconfig | grep $(cat nodes/master-node-ip) | xargs | cut -d' ' -f4")
      echo "NETMASK: $netmask"
      cat $(pwd)/nodes/nfs-fstab
      sed -i "s|XXXX|$uuid|" $(pwd)/nodes/nfs-fstab
      echo " ------- /etc/fstab ---------"
      cat $(pwd)/nodes/nfs-fstab
      echo "-----> Processing /etc/exports"
      rm $(pwd)/nodes/nfs-exports && cp $(pwd)/nodes/nfs-exports-template $(pwd)/nodes/nfs-exports
      cat $(pwd)/nodes/nfs-exports
      cidr=$(ipcalc -n ${ipaddress} $netmask | grep "Network:" | xargs | cut -d' ' -f2)
      #cidr=$(echo $temp | cut -d'/' -f1)
      #prefix=$(echo $temp | cut -d'/' -f2)
      echo "CIDR: $cidr"
      sed -i "s|XXXX|$cidr|" $(pwd)/nodes/nfs-exports
      echo " ------- /etc/exports ---------"
      cat $(pwd)/nodes/nfs-exports
      scp $(pwd)/nodes/nfs-fstab ubuntu@${ipaddress}:/home/ubuntu/nodes/nfs-fstab
      scp $(pwd)/nodes/nfs-exports ubuntu@${ipaddress}:/home/ubuntu/nodes/nfs-exports
      scp $(pwd)/nodes/nfs-device-name ubuntu@${ipaddress}:/home/ubuntu/nodes/nfs-device-name
      scp $(pwd)/nodes/05a-configure-nfs-server.sh ubuntu@${ipaddress}:/home/ubuntu/nodes/05a-configure-nfs-server.sh
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/05a-configure-nfs-server.sh'
   else
      scp $(pwd)/nodes/nfs-device-name ubuntu@${ipaddress}:/home/ubuntu/nodes/nfs-device-name
      scp $(pwd)/nodes/05b-configure-nfs-client.sh ubuntu@${ipaddress}:/home/ubuntu/nodes/05b-configure-nfs-client.sh
      ssh ubuntu@${ipaddress} '/home/ubuntu/nodes/05b-configure-nfs-client.sh'
   fi
done

for line in $(cat hosts); do
   ipaddress=$(echo $line | cut -d"," -f1)
   role=$(echo $line | cut -d"," -f2)
   ssh ubuntu@${ipaddress} 'sudo reboot'
done
echo 'Finishing up NFS set up, check back after 2 minutes...'
./countdown 00:02:00

echo 'Check if nodes have rebooted...'
hosts=$(cat ipaddresses)
parallel-ssh -i -H "$hosts" 'echo "Hello, world!" from $(hostname)'
