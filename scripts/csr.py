import os
import configparser
import sys
import json


vars_file = 'vars.ini'

ca_section_name = 'ca'
csr_section_name = 'csr'
etcd_section_name = 'etcd-cluster'
k8s_section_name = 'k8s'


ca_csr = {
    "CN": "CA",
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
        "127.0.0.1"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": []
}

apiserver_csr = {
    "CN": "kube-apiserver",
    "hosts": [
        "127.0.0.1",
        "kubernetes",
        "kubernetes.default",
        "kubernetes.default.svc",
        "kubernetes.default.svc.cluster",
        "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": []
}

apiserver_kubelet_client_csr = {
    "CN": "apiserver-kubelet-client",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": []
}

aggregator_ca_csr = {
    "CN": "Aggregator CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [],
    "ca": {
        "expiry": ""
    }
}

proxy_client_csr = {
    "CN": "aggregator",
    "hosts": [
        "127.0.0.1",
        "kubernetes",
        "kubernetes.default",
        "kubernetes.default.svc",
        "kubernetes.default.svc.cluster",
        "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": []
}

k8s_admin_csr = {
    "CN": "kubernetes-admin",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": []
}


controller_manager_csr = {
    "CN": "system:kube-controller-manager",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": []
}

scheduler_csr = {
    "CN": "system:kube-scheduler",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": []
}

kubeproxy_csr = {
    "CN": "system:kube-proxy",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": []
}


def generate_csr_names_field(csr):
    csr_contents = {}

    config = configparser.ConfigParser()
    config.read(vars_file)

    for option in config.options(csr_section_name):
        value = config.get(csr_section_name, option)
        csr_contents[option.upper()] = value
    csr['names'].append(csr_contents)

    return config, csr


def write_csr_file(filename, csr):
    with open(filename, 'w') as fdst:
        json.dump(csr, fdst, indent=4)


def generate_ca_csr_config():
    ca_csr_filename = 'files/ca-csr.json'

    config, csr = generate_csr_names_field(ca_csr)
    csr['ca']['expiry'] = config.get(ca_section_name, 'expire')

    write_csr_file(ca_csr_filename, csr)


def generate_aggregator_ca_csr_config():
    aggregator_ca_csr_filename = 'files/aggregator-ca-csr.json'

    config, csr = generate_csr_names_field(aggregator_ca_csr)
    csr['ca']['expiry'] = config.get(ca_section_name, 'expire')

    write_csr_file(aggregator_ca_csr_filename, csr)


def generate_etcd_csr_config():
    etcd_csr_filename = 'files/etcd-csr.json'

    config, csr = generate_csr_names_field(etcd_csr)

    for option in config.options(etcd_section_name):
        value = config.get(etcd_section_name, option)
        ip = value.split('//')[1].split(':')[0]
        csr['hosts'].append(ip)

    write_csr_file(etcd_csr_filename, csr)


def generate_apiserver_csr_config():
    apiserver_csr_filename = 'files/kube-apiserver-csr.json'
    proxy_client_csr_filename = 'files/proxy-client-csr.json'

    config, csr = generate_csr_names_field(apiserver_csr)

    # 写入hosts字段
    for option in config.options(k8s_section_name):
        if option.startswith('master_host'):
            host = config.get(k8s_section_name, option)
            csr['hosts'].append(host)

    # hosts 字段增加 vip和service-cluster-ip-range 的第一个IP
    vip = config.get(k8s_section_name, 'vip')
    svc_ip_range = config.get(
        k8s_section_name, 'service-cluster-ip-range')
    svc_first_ip = '.'.join(svc_ip_range.split('/')[0].split('.')[:3]) + '.1'

    csr['hosts'].append(vip)
    csr['hosts'].append(svc_first_ip)

    write_csr_file(apiserver_csr_filename, csr)
    write_csr_file(proxy_client_csr_filename, csr)


def generate_proxyclient_csr_config():
    proxy_client_csr_filename = 'files/proxy-client-csr.json'

    config, csr = generate_csr_names_field(proxy_client_csr)

    # 写入hosts字段
    for option in config.options(k8s_section_name):
        if option.startswith('master_host'):
            host = config.get(k8s_section_name, option)
            csr['hosts'].append(host)

    # hosts 字段增加 vip和service-cluster-ip-range 的第一个IP
    vip = config.get(k8s_section_name, 'vip')
    svc_ip_range = config.get(
        k8s_section_name, 'service-cluster-ip-range')
    svc_first_ip = '.'.join(svc_ip_range.split('/')[0].split('.')[:3]) + '.1'

    csr['hosts'].append(vip)
    csr['hosts'].append(svc_first_ip)
    write_csr_file(proxy_client_csr_filename, csr)


def generate_apiserver_kubelet_client_csr_config():
    apiserver_kubelet_client_csr_filename = 'files/apiserver-kubelet-client-csr.json'

    config, csr = generate_csr_names_field(apiserver_kubelet_client_csr)
    csr['names'][0]['O'] = 'system:masters'

    write_csr_file(apiserver_kubelet_client_csr_filename, csr)


def generate_k8s_admin_csr_config():
    k8s_admin_csr_filename = 'files/k8s-admin-csr.json'

    config, csr = generate_csr_names_field(k8s_admin_csr)
    csr['names'][0]['O'] = 'system:masters'

    write_csr_file(k8s_admin_csr_filename, csr)


def generate_controller_manager_csr_config():
    controller_manager_csr_filename = 'files/kube-controller-manager-csr.json'

    config, csr = generate_csr_names_field(controller_manager_csr)

    # 写入hosts字段
    for option in config.options(k8s_section_name):
        if option.startswith('master_host'):
            host = config.get(k8s_section_name, option)
            csr['hosts'].append(host)
    csr['names'][0]['O'] = 'system:kube-controller-manager'

    write_csr_file(controller_manager_csr_filename, csr)


def generate_scheduler_csr_config():
    scheduler_csr_filename = 'files/kube-scheduler-csr.json'

    config, csr = generate_csr_names_field(scheduler_csr)

    # 写入hosts字段
    for option in config.options(k8s_section_name):
        if option.startswith('master_host'):
            host = config.get(k8s_section_name, option)
            csr['hosts'].append(host)
    csr['names'][0]['O'] = 'system:kube-scheduler'

    write_csr_file(scheduler_csr_filename, csr)


def generate_kubeproxy_csr_config():
    kubeproxy_csr_filename = 'files/kube-proxy-csr.json'

    _, csr = generate_csr_names_field(kubeproxy_csr)
    csr['names'][0]['O'] = 'system:kube-proxy'

    write_csr_file(kubeproxy_csr_filename, csr)


if __name__ == "__main__":
    generate_ca_csr_config()
    generate_aggregator_ca_csr_config()
    generate_etcd_csr_config()
    generate_apiserver_csr_config()
    generate_apiserver_kubelet_client_csr_config()
    generate_k8s_admin_csr_config()
    generate_proxyclient_csr_config()
    generate_controller_manager_csr_config()
    generate_scheduler_csr_config()
    generate_kubeproxy_csr_config()
