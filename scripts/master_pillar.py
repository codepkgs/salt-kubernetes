import sys
import configparser
import os

vars_file = 'vars.ini'


def generate_master_pillar_file():
    master_pillar_filename = 'k8s-master.sls'
    etcd_initial_cluster = ''

    master_section_name = 'k8s-master'
    etcd_section_name = 'etcd_cluster'

    config = configparser.ConfigParser()
    config.read(vars_file)

    # 产生 etcd 的 etcd_serers 字段
    for option in config.options(etcd_section_name):
        value = config.get(etcd_section_name, option)
        ip = ':'.join(value.split(':')[:2]) + ':2379'
        etcd_initial_cluster += '{},'.format(ip)

    etcd_initial_cluster = etcd_initial_cluster.rstrip(',')

    # 写入其他字段
    service_cluster_ip_range = config.get(
        master_section_name, 'service-cluster-ip-range')

    service_node_port_range = config.get(
        master_section_name, 'service-node-port-range')

    # 写入文件
    with open(master_pillar_filename, 'w') as fdst:
        fdst.write("etcd_servers: '{}'{}".format(
            etcd_initial_cluster, os.linesep))
        fdst.write("service_cluster_ip_range: '{}'{}".format(
            service_cluster_ip_range, os.linesep))
        fdst.write("service_node_port_range: '{}'{}".format(
            service_node_port_range, os.linesep))


if __name__ == "__main__":
    generate_master_pillar_file()
