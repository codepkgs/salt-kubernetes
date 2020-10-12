import os
import configparser
import sys
import json


vars_file = 'vars.ini'

ca_section_name = 'ca'
csr_section_name = 'csr'
etcd_section_name = 'etcd_cluster'

ca_csr = {
    "CN": "Root CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [],
    "ca": {
        "expiry": ""
    }
}

etcd_csr = {
    "CN": "etcd cluster",
    "hosts": [
        "127.0.0.1",
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": []
}


def generate_ca_csr_config():
    ca_csr_filename = 'files/ca-csr.json'
    csr_contents = {}

    config = configparser.ConfigParser()
    config.read(vars_file)
    if not config.has_section(csr_section_name):
        print('the section: {}, NOT FOUND'.format(csr_section_name))
        sys.exit(0)

    for option in config.options(csr_section_name):
        value = config.get(csr_section_name, option)
        csr_contents[option.upper()] = value

    ca_csr['names'].append(csr_contents)
    ca_csr['ca']['expiry'] = config.get(ca_section_name, 'expire')

    with open(ca_csr_filename, 'w') as fdst:
        json.dump(ca_csr, fdst, indent=4)


def generate_etcd_csr_config():
    etcd_csr_filename = 'files/etcd-csr.json'
    csr_contents = {}

    config = configparser.ConfigParser()
    config.read(vars_file)
    if not config.has_section(etcd_section_name):
        print('the section: {}, NOT FOUND'.format(etcd_section_name))
        sys.exit(0)

    for option in config.options(csr_section_name):
        value = config.get(csr_section_name, option)
        csr_contents[option.upper()] = value

    etcd_csr['names'].append(csr_contents)

    for option in config.options(etcd_section_name):
        value = config.get(etcd_section_name, option)
        ip = value.split('//')[1].split(':')[0]
        etcd_csr['hosts'].append(ip)

    with open(etcd_csr_filename, 'w') as fdst:
        json.dump(etcd_csr, fdst, indent=4)


if __name__ == "__main__":
    generate_ca_csr_config()
    generate_etcd_csr_config()
