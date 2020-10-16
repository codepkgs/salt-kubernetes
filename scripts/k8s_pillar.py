import sys
import configparser
import os

vars_file = 'vars.ini'


def generate_master_pillar_file():
    master_pillar_filename = 'k8s-master.sls'
    etcd_initial_cluster = ''

    k8s_section_name = 'k8s'
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
    cluster_cidr = config.get(k8s_section_name, 'cluster-cidr')

    service_cluster_ip_range = config.get(
        k8s_section_name, 'service-cluster-ip-range')

    service_node_port_range = config.get(
        k8s_section_name, 'service-node-port-range')

    # 写入文件
    with open(master_pillar_filename, 'w') as fdst:
        fdst.write("etcd_servers: '{}'{}".format(
            etcd_initial_cluster, os.linesep))
        fdst.write("cluster_cidr: '{}'{}".format(
            cluster_cidr, os.linesep))
        fdst.write("service_cluster_ip_range: '{}'{}".format(
            service_cluster_ip_range, os.linesep))
        fdst.write("service_node_port_range: '{}'{}".format(
            service_node_port_range, os.linesep))


def generate_worker_pillar_file():
    worker_pillar_filename = 'k8s-worker.sls'

    k8s_section_name = 'k8s'

    config = configparser.ConfigParser()
    config.read(vars_file)

    # 写入其他字段
    cluster_dns = config.get(k8s_section_name, 'cluster-dns')
    cluster_cidr = config.get(k8s_section_name, 'service-cluster-ip-range')

    pod_cidr = config.get(
        k8s_section_name, 'cluster-cidr')

    # 写入文件
    with open(worker_pillar_filename, 'w') as fdst:
        fdst.write("cluster_dns: '{}'{}".format(
            cluster_dns, os.linesep))
        fdst.write("cluster_cidr: '{}'{}".format(
            cluster_cidr, os.linesep))
        fdst.write("pod_cidr: '{}'{}".format(
            pod_cidr, os.linesep))


if __name__ == "__main__":
    generate_master_pillar_file()
    generate_worker_pillar_file()
