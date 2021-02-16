# deploy-pi-kubernetes-cluster

## Work in progress...

## Initial steps
1. Download raspberry pi imager (balenaEther or Raspberry Pi imager)
2. Burn 64-bit Ubuntu 20.04 LTS onto micro-SD card(s)
3. Edit user-data in micro-SD cards
4. Insert micro-SD cards and boot up RPi4s
5. Get IP addresses of RPi4s - write IP addresses in hosts file (use `hosts-template` as template)
6. Edit .env file (use .env-template as template) and add key info
7. Run `change-host-passwords.sh`
8. Run `config-hosts.sh`

Checks:
1. `kubectl cluster-info`: Provides info on running clusters
