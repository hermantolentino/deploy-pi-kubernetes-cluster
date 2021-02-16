#!/usr/bin/env python3

import yaml
from dotenv import load_dotenv
import os

load_dotenv()
ns_addresses = os.getenv('NS_ADDRESSES').split(",")
import netifaces as ni
ni.ifaddresses('eth0')
eth0_ip = ni.ifaddresses('eth0')[ni.AF_INET][0]['addr']
gateway_ip = ni.gateways()['default'][2][0]
print('eth0:',eth0_ip)
print('gateway_ip:',gateway_ip)
print('ns_addresses:', ns_addresses)
with open('/home/ubuntu/nodes/template-50-cloud-init.yaml') as file:
    # The FullLoader parameter handles the conversion from YAML
    # scalar values to Python the dictionary format
    yaml_dict = yaml.load(file, Loader=yaml.FullLoader)
    print('---before---')
    print(yaml_dict)
    # ip address in CIDR format
    eth0_addresses = ["{}/22".format(eth0_ip)]
    yaml_dict['network']['ethernets']['eth0']['addresses'] = eth0_addresses
    yaml_dict['network']['ethernets']['eth0']['gateway4'] = gateway_ip
    yaml_dict['network']['ethernets']['eth0']['nameservers']['addresses'] = ns_addresses
    print('---after---')
    print(yaml_dict)

with open('/home/ubuntu/nodes/50-cloud-init.yaml', 'w') as file:
    documents = yaml.dump(yaml_dict, file)
