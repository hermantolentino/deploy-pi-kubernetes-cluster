# deploy-pi-kubernetes-cluster

## Work in progress...

## Hardware
1. At least 2 Raspberry Pi 4 (RPi4) single board computers with 4GB memory
2. 64GB micro-SD cards for RPi4's
3. 4-port network switch, 1-foot Cat6 patch cables
4. Computer running Ubuntu Linux (setup machine) with SD card reader (connected to the same network as RPi4's)

## Initial steps
1. Download Raspberry Pi imager (balenaEtcher or Raspberry Pi imager)
2. Write `64-bit Ubuntu 20.04 LTS` image onto micro-SD card(s)
3. Insert micro-SD cards and boot up RPi4s.
4. Reserve the IP adddress for each RPi4 in your router management software / web interface. This enables each RPi4 to get the same IP address everytime it reboots and requests an IP address through DHCP.
5. You can also obtain the gateway IP address from your router (needed for Step 8).
6. Git clone this repository on setup machine, then `cd` to the repository folder `deploy-pi-kubernetes-cluster`.
7. Using `hosts-template` as template, create a file called `hosts`. Write the IP addresses in `hosts` file, one IP address per line (use `hosts-template` as template) and pick which one you want to be k8s master and worker nodes. These are the IP addresses obtained by RPi4s from your router and should be identifiable through the label 'Raspberry Pi Trading Ltd'.
8. Copy `.env-template` to `.env`. Open `.env` for editing and add key info.
9. On setup machine, make sure there is no `.password_changed` file, delete it if it exists (`rm .password_changed`). Run `01-change-host-passwords.sh` to update default Ubuntu passwords on running RPi4's.
10. If you haven't yet, generate SSH key pair with the script `02a-generate-ssh-key-pair.sh`. (This creates private and public keys in your Linux home `.ssh` folder. Skip this if you already have generated a SSH key pair you will use for the cluster.)
11. If you have generated your SSH key pair, run the script, `02b-upload-ssh-public-keys.sh`, to upload your SSH public kay to the RPi4s and enable password-less SSH to master and worker nodes from the setup machine.
12. *Note: Other cluster admins can clone the same repository on their accounts in the Linux setup machine and run Step 10 and Step 11.*
13. Run configuration script, `03-config-hosts.sh`, to configure RPi4's. `config-hosts.sh` sets up each RPi4.
14. Run configuration script, `04-configure-cluster.sh`, to configure k8s on the RPi4s.

Checks on completion (on master node):
1. If successful, you should be able to SSH into the k8s master node without a password from the setup machine.
2. `kubectl get nodes` should show k8s cluster ready for use
3. `kubectl cluster-info` provides info on running clusters
