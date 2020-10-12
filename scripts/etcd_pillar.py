import sys
import configparser
import os


vars_file = 'vars.ini'
etcd_section_name = 'etcd_cluster'


def generate_etcd_pillar_file():
    etcd_pillar_filename = 'etcd.sls'
    ca_filename = 'certs/ca.pem'
    peer_ca_filename = 'certs/ca.pem'
    etcd_filename = 'certs/etcd.pem'
    etcd_key_filename = 'certs/etcd-key.pem'
    etcd_peer_filename = 'certs/etcd.pem'
    etcd_peer_key_filename = 'certs/etcd-key.pem'

    etcd_initial_cluster = ''
    config = configparser.ConfigParser()
    config.read(vars_file)
    if not config.has_section(etcd_section_name):
        print('the section: {}, NOT FOUND'.format(etcd_section_name))
        sys.exit(0)

    for option in config.options(etcd_section_name):
        value = config.get(etcd_section_name, option)
        etcd_initial_cluster += '{}={},'.format(option, value)

    etcd_initial_cluster = etcd_initial_cluster.rstrip(',')

    with open(etcd_pillar_filename, 'w') as fdst:
        fdst.write("etcd_initial_cluster: '{}'{}".format(
            etcd_initial_cluster, os.linesep))

        with open(ca_filename, 'r') as f:
            fdst.write('etcd_trusted_ca_content: |{}'.format(os.linesep))
            for line in f:
                fdst.write('{}{}'.format('    ', line))

        with open(peer_ca_filename, 'r') as f:
            fdst.write('etcd_peer_trusted_ca_content: |{}'.format(os.linesep))
            for line in f:
                fdst.write('{}{}'.format('    ', line))

        with open(etcd_filename, 'r') as f:
            fdst.write('etcd_cert_content: |{}'.format(os.linesep))
            for line in f:
                fdst.write('{}{}'.format('   ', line))

        with open(etcd_key_filename, 'r') as f:
            fdst.write('etcd_key_content: |{}'.format(os.linesep))
            for line in f:
                fdst.write('{}{}'.format('   ', line))

        with open(etcd_peer_filename, 'r') as f:
            fdst.write('etcd_peer_cert_content: |{}'.format(os.linesep))
            for line in f:
                fdst.write('{}{}'.format('   ', line))

        with open(etcd_peer_key_filename, 'r') as f:
            fdst.write('etcd_peer_key_content: |{}'.format(os.linesep))
            for line in f:
                fdst.write('{}{}'.format('   ', line))


if __name__ == "__main__":
    generate_etcd_pillar_file()
