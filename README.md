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
3. Edit `user-data` files in micro-SD cards:
```YAML
chpasswd:
  expire: false
  list:
  - ubuntu:ubuntu

 # Enable password authentication with the SSH daemon
ssh_pwauth: true
```
4. Git clone this repository on setup machine, then `cd` to the repository folder.
5. Generate SSH key pair with `generate-ssh-key-pair.sh` (This creates private and public keys in your Linux home `.ssh` folder. The configuration script will upload SSH public key to RPi4s.)
6. Insert micro-SD cards and boot up RPi4s.
7. On setup machine, create a `hosts` file using `hosts-template`.
8. Log in to each RPi4, and using `ip address show` at the command line, get `eth0` IP addresses of RPi4s.
9. Write IP addresses in `hosts` file, one IP address per line (use `hosts-template` as template) and pick which one you want to be the k8s master node. (Note this down for the `.env` below.)
10. On setup machine, edit `.env` file (use `.env-template` as template) and add key info, including IP address of master node.
11. On setup machine, Run `change-host-passwords.sh` to update default Ubuntu passwords on RPi4's
12. Run configuration script, `config-hosts.sh`, to configure RPi4's. `config-hosts.sh` sets up each RPi4.

`config-hosts.sh`:
1. Updates hostnames to identify master and worker nodes
2. Installs SSH public key to each RPi4
3. Copies (using `scp`) setup machine `nodes` folder contents to RPi4s
4. Installs packages (docker, k8s, Python packages)
5. Configures network for RPi4's
6. Configures k8s master and worker nodes and joins worker node(s) to master node.

Checks on completion (on master node):
1. If successful, you should be able to SSH into the k8s master node without a password from the setup machine.
2. `kubectl get nodes` should show k8s cluster ready for use
3. `kubectl cluster-info` provides info on running clusters
