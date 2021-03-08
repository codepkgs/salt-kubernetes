# coding: utf-8
import sys
import configparser
import os

vars_file = 'vars.ini'


def generate_etcd_pillar_file():
    etcd_section_name = 'etcd-cluster'
    etcd_pillar_filename = 'etcd.sls'
    ca_filename = 'certs/ca.pem'
    peer_ca_filename = 'certs/ca.pem'
    etcd_filename = 'certs/k8s-master/etcd.pem'
    etcd_key_filename = 'certs/k8s-master/etcd-key.pem'
    etcd_peer_filename = 'certs/k8s-master/etcd.pem'
    etcd_peer_key_filename = 'certs/k8s-master/etcd-key.pem'

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


def generate_master_pillar_file():
    master_pillar_filename = 'k8s-master.sls'
    etcd_initial_cluster = ''

    k8s_section_name = 'k8s'
    etcd_section_name = 'etcd-cluster'

    config = configparser.ConfigParser()
    config.read(vars_file)

    # 产生 etcd 的 etcd_serers 字段
    for option in config.options(etcd_section_name):
        value = config.get(etcd_section_name, option)
        ip = ':'.join(value.split(':')[:2]) + ':2379'
        etcd_initial_cluster += '{},'.format(ip)

    etcd_initial_cluster = etcd_initial_cluster.rstrip(',')

    # 写入其他字段
    pod_cidr = config.get(k8s_section_name, 'pod-cidr')

    service_cluster_ip_range = config.get(
        k8s_section_name, 'service-cluster-ip-range')

    service_node_port_range = config.get(
        k8s_section_name, 'service-node-port-range')

    # 写入文件
    with open(master_pillar_filename, 'w') as fdst:
        fdst.write("etcd_servers: '{}'{}".format(
            etcd_initial_cluster, os.linesep))
        fdst.write("pod_cidr: '{}'{}".format(
            pod_cidr, os.linesep))
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
    service_cidr = config.get(k8s_section_name, 'service-cluster-ip-range')

    pod_cidr = config.get(
        k8s_section_name, 'pod-cidr')

    # 写入文件
    with open(worker_pillar_filename, 'w') as fdst:
        fdst.write("cluster_dns: '{}'{}".format(
            cluster_dns, os.linesep))
        fdst.write("service_cidr: '{}'{}".format(
            service_cidr, os.linesep))
        fdst.write("pod_cidr: '{}'{}".format(
            pod_cidr, os.linesep))


def generate_apiserver_ha_pillar_file():
    ha_pillar_filename = 'k8s-apiserver-ha.sls'
    k8s_section_name = 'k8s'
    k8s_ha_section_name = 'k8s-apiserver-ha'

    config = configparser.ConfigParser()
    config.read(vars_file)

    # 写入其他字段
    ha_vip = config.get(k8s_ha_section_name, 'apiserver-virutal-ip')
    ha_vip_bind_interface = config.get(
        k8s_ha_section_name, 'apiserver-virutal-ip-bind-interface')
    ha_keepalived_virtual_router_id = config.get(
        k8s_ha_section_name, 'apiserver-keepalived-virtual-router-id')

    # 获取 master_host，写入 pillar数据，供nginx stream 使用
    master_hosts = []
    for option in config.options(k8s_section_name):
        if option.startswith('master_host'):
            host = config.get(k8s_section_name, option)
            master_hosts.append(host)

    # 写入文件
    with open(ha_pillar_filename, 'w') as fdst:
        fdst.write("master_hosts: {}{}".format(master_hosts, os.linesep))
        fdst.write("k8s_ha_keepalived_virtual_router_id: {}{}".format(
            ha_keepalived_virtual_router_id, os.linesep))
        fdst.write("k8s_ha_apiserver_vip: '{}'{}".format(ha_vip, os.linesep))
        fdst.write("k8s_ha_vip_bind_interface: '{}'{}".format(
            ha_vip_bind_interface, os.linesep))


def generate_ingress_nginx_ha_pillar_file():
    ingress_nginx_pillar_filename = 'k8s-ingress-nginx.sls'
    k8s_ingress_nginx_section_name = 'k8s-ingress-nginx'

    config = configparser.ConfigParser()
    config.read(vars_file)

    # 写入其他字段
    ingress_nginx_hosts = config.get(
        k8s_ingress_nginx_section_name, 'ingress-nginx-hosts').split(',')
    ingress_nginx_virutal_ip = config.get(k8s_ingress_nginx_section_name,
                                          'ingress-nginx-virutal-ip')
    ingress_nginx_virutal_ip_bind_interface = config.get(
        k8s_ingress_nginx_section_name, 'ingress-nginx-virutal-ip-bind-interface')
    ingress_keepalived_virtual_router_id = config.get(
        k8s_ingress_nginx_section_name, 'ingress-keepalived-virtual-router-id')

    # 写入文件
    with open(ingress_nginx_pillar_filename, 'w') as fdst:

        fdst.write("ingress_nginx_hosts: {}{}".format(
            ingress_nginx_hosts, os.linesep))
        fdst.write("ingress_nginx_virutal_ip: '{}'{}".format(
            ingress_nginx_virutal_ip, os.linesep))
        fdst.write("ingress_nginx_virutal_ip_bind_interface: '{}'{}".format(
            ingress_nginx_virutal_ip_bind_interface, os.linesep))
        fdst.write("ingress_keepalived_virtual_router_id: {}{}".format(
            ingress_keepalived_virtual_router_id, os.linesep))


if __name__ == "__main__":
    generate_etcd_pillar_file()
    generate_master_pillar_file()
    generate_worker_pillar_file()
    generate_apiserver_ha_pillar_file()
    generate_ingress_nginx_ha_pillar_file()
