# deploy-pi-kubernetes-cluster

## Work in progress...

## Initial steps
1. Download Raspberry Pi imager (balenaEtcher or Raspberry Pi imager)
2. Write `64-bit Ubuntu 20.04 LTS` image onto micro-SD card(s)
3. Edit `user-data` files in micro-SD cards
4. Generate SSH key pair with `generate-ssh-key-pair.sh` (This creates private and public keys in your Linux home `.ssh` folder. The configuration script will upload SSH public key to RPi4s.)
5. Insert micro-SD cards and boot up RPi4s. Using `ip address show` at the command line, get IP addresses of RPi4s. Write IP addresses in `hosts` file, one IP address per line (use `hosts-template` as template) and pick which one you want to be the k8s master node. (Note this down for the `.env` below.)
6. Edit `.env` file (use `.env-template` as template) and add key info, including IP address of master node.
7. Run `change-host-passwords.sh` to update default Ubuntu passwords
8. Run `config-hosts.sh` to configure RPi4's. `config-hosts.sh` sets up each RPi4:
  a. Updates hostnames to identify master and worker nodes
  b. Installs SSH public key
  c. Copies (using `scp`)`nodes` folder contents to RPi4s
  d. Installs packages (docker, k8s, Python packages)
  e. Configures network
  f. Configures k8s master and worker nodes and joins worker node(s) to master node.

Checks:
1. `kubectl cluster-info`: Provides info on running clusters
