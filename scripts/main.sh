#!/bin/bash
set -e

# 定义全局变量
k8s_master_certs_dir="../salt/base/k8s-master/files/certs"
vip_address="$(grep '\<vip\>' vars.ini | awk -F'=' '{print $2}' | awk '{print $1}')"

clean() {
    # 删除certs目录下的所有内容
    rm -rf certs/* &> /dev/null

    # 删除 etcd pillar 数据
    rm -rf etcd.sls ../pillar/base/etcd/sls/etcd.sls &> /dev/null
    rm -rf k8s-master.sls ../pillar/base/k8s-master/sls/k8s-master.sls &> /dev/null
    
    # 删除 csr json 文件
    rm -rf files/ca-csr.json &> /dev/null
    rm -rf files/etcd-csr.json &> /dev/null
    rm -rf files/kube-apiserver-csr.json &> /dev/null
    rm -rf files/aggregator-ca-csr.json &> /dev/null
    rm -rf files/apiserver-kubelet-client-csr.json &> /dev/null
    rm -rf files/proxy-client-csr.json &> /dev/null
    rm -rf files/kube-controller-manager-csr.json &> /dev/null

    # 删除 k8s-master certs 文件
    rm -rf ${k8s_master_certs_dir}/* &> /dev/null

    # 删除 kubeconfig
    rm -rf ../salt/base/k8s-master/files/kubeconfig/* &> /dev/null
}

init() {
    local kubeconfig_dir='../salt/base/k8s-master/files/kubeconfig/'
    # 产生csr文件
    python csr.py

    # 产生证书
    ca
    aggregator_ca
    etcd
    gen_sa
    apiserver
    controller_manager
    apiserver_kubelet_client
    proxy_client_metrics_server
    k8s_admin

    # kubeconfig
    controller_manager_kubeconfig

    # mv kubeconfig
    mv kube-controller-manager.kubeconfig $kubeconfig_dir/

    # 复制证书
    if [ ! -d ${k8s_master_certs_dir} ]; then
        mkdir ${k8s_master_certs_dir}
    fi
    cp -a ./certs/* ../salt/base/k8s-master/files/certs/ 

    # 产生etcd pillar数据
    python etcd_pillar.py && mv etcd.sls ../pillar/base/etcd/sls/
    python master_pillar.py && mv k8s-master.sls ../pillar/base/k8s-master/sls/
}

gen_cert() {
    cert_name=$1
    cert_filename=$2
    cert_csr=$3
    csr_json=$4

    if [ ! -f "./certs/ca.pem" -o ! -f "./certs/ca-key.pem" ]; then
        ca
    fi

    if [ "$force" == "1" ]; then
        cfssl gencert -ca ./certs/ca.pem -ca-key ./certs/ca-key.pem \
            -config ./files/config.json -profile peer \
            ./files/${csr_json} | cfssljson -bare ./certs/${cert_name}
        rm -rf ./certs/${cert_csr} &> /dev/null
    elif [ ! -f "${cert_filename}" ]; then
        cfssl gencert -ca ./certs/ca.pem -ca-key ./certs/ca-key.pem \
            -config ./files/config.json -profile peer \
            ./files/${csr_json} | cfssljson -bare ./certs/${cert_name}
        rm -rf ./certs/${cert_csr} &> /dev/null
    else
        echo "warning: ${cert_name} cert is exist now, if you want to generate, please use --force"
    fi
}

gen_cert_aggregator() {
    cert_name=$1
    cert_filename=$2
    cert_csr=$3
    csr_json=$4

    if [ ! -f "./certs/ca.pem" -o ! -f "./certs/ca-key.pem" ]; then
        ca
    fi

    if [ "$force" == "1" ]; then
        cfssl gencert -ca ./certs/aggregator-ca.pem -ca-key ./certs/aggregator-ca-key.pem \
            -config ./files/config.json -profile peer \
            ./files/${csr_json} | cfssljson -bare ./certs/${cert_name}
        rm -rf ./certs/${cert_csr} &> /dev/null
    elif [ ! -f "${cert_filename}" ]; then
        cfssl gencert -ca ./certs/aggregator-ca.pem -ca-key ./certs/aggregator-ca-key.pem \
            -config ./files/config.json -profile peer \
            ./files/${csr_json} | cfssljson -bare ./certs/${cert_name}
        rm -rf ./certs/${cert_csr} &> /dev/null
    else
        echo "warning: ${cert_name} cert is exist now, if you want to generate, please use --force"
    fi
}

gen_kubeconfig() {
    api_server=$1
    kubeconfig_filename=$2
    user=$3

    # 1. 设置集群参数
    kubectl config set-cluster kubernetes \
        --certificate-authority=./certs/ca.pem \
        --embed-certs=true \
        --server=${api_server} \
        --kubeconfig=${kubeconfig_filename}

    # 2. 设置客户端认证参数
    kubectl config set-credentials ${user} \
        --embed-certs=true \
        --client-certificate=./certs/kube-controller-manager.pem \
        --client-key=./certs/kube-controller-manager-key.pem \
        --kubeconfig=${kubeconfig_filename}

    # 3. 设置上下文参数
    kubectl config set-context ${user} \
        --cluster=kubernetes \
        --user=${user} \
        --kubeconfig=${kubeconfig_filename}

    # 4. 设置当前所使用的上下文
    kubectl config use-context ${user} \
        --kubeconfig=${kubeconfig_filename}
}

ca() {
    local cert_filename='certs/ca.pem'
    local cert_csr='ca.csr'
    local csr_json='ca-csr.json'

    if [ "$force" == "1" ]; then
        cfssl gencert -initca ./files/$csr_json | cfssljson -bare ./certs/ca
        rm -rf ./certs/$cert_csr &> /dev/null
    elif [ ! -f "$cert_filename" ]; then
        cfssl gencert -initca ./files/$csr_json | cfssljson -bare ./certs/ca
        rm -rf ./certs/$cert_csr &> /dev/null
    else
        echo "warning: ca cert is exist now, if you want to generate, please use --force"
    fi
}

aggregator_ca() {
    local cert_name='aggregator-ca'
    local cert_filename='certs/aggregator-ca.pem'
    local cert_csr='aggregator-ca.csr'
    local csr_json='aggregator-ca-csr.json'

    if [ "$force" == "1" ]; then
        cfssl gencert -initca ./files/${csr_json} | cfssljson -bare ./certs/${cert_name}
        rm -rf ./certs/${cert_csr} &> /dev/null
    elif [ ! -f "${cert_filename}" ]; then
        cfssl gencert -initca ./files/${csr_json} | cfssljson -bare ./certs/${cert_name}
        rm -rf ./certs/${cert_csr} &> /dev/null
    else
        echo "warning: ${cert_name} cert is exist now, if you want to generate, please use --force"
    fi
}

etcd() {
    local cert_name='etcd'
    local cert_filename='certs/etcd.pem'
    local cert_csr='etcd.csr'
    local csr_json='etcd-csr.json'

    gen_cert $cert_name $cert_filename $cert_csr $csr_json
}

gen_sa() {
    local cert_name='service-account'

    if [ "$force" == "1" ]; then
        openssl genrsa -out ./certs/${cert_name}.key 2048
        openssl rsa -in ./certs/${cert_name}.key -pubout -outform pem -out ./certs/${cert_name}.pub
    elif [ ! -f "./certs/${cert_name}.key" -o ! -f "./certs/${cert_name}.pub" ]; then
        openssl genrsa -out ./certs/${cert_name}.key 2048
        openssl rsa -in ./certs/${cert_name}.key -pubout -outform pem -out ./certs/${cert_name}.pub
    else
        echo "warning: ${cert_name} cert is exist now, if you want to generate, please use --force"
    fi
}

apiserver() {
    local cert_name='kube-apiserver'
    local cert_filename='certs/kube-apiserver.pem'
    local cert_csr='kube-apiserver.csr'
    local csr_json='kube-apiserver-csr.json'

    gen_cert $cert_name $cert_filename $cert_csr $csr_json
}

controller_manager() {
    local cert_name='kube-controller-manager'
    local cert_filename='certs/kube-controller-manager.pem'
    local cert_csr='kube-controller-manager.csr'
    local csr_json='kube-controller-manager-csr.json'

    gen_cert $cert_name $cert_filename $cert_csr $csr_json
}

apiserver_kubelet_client() {
    local cert_name='apiserver-kubelet-client'
    local cert_filename='certs/apiserver-kubelet-client.pem'
    local cert_csr='apiserver-kubelet-client.csr'
    local csr_json='apiserver-kubelet-client-csr.json'

    gen_cert $cert_name $cert_filename $cert_csr $csr_json
}

proxy_client_metrics_server() {
    local cert_name='proxy-client'
    local cert_filename='certs/proxy-client.pem'
    local cert_csr='proxy-client.csr'
    local csr_json='proxy-client-csr.json'

    gen_cert_aggregator $cert_name $cert_filename $cert_csr $csr_json
}

k8s_admin() {
    local cert_name='k8s-admin'
    local cert_filename='certs/k8s-admin.pem'
    local cert_csr='k8s-admin.csr'
    local csr_json='k8s-admin-csr.json'

    gen_cert $cert_name $cert_filename $cert_csr $csr_json
}

controller_manager_kubeconfig() {
    local vip="https://$vip_address:6443"
    gen_kubeconfig $vip kube-controller-manager.kubeconfig system:kube-controller-manager
}

help() {
    echo "before use this script, please modify json file in files directory"
    echo "usage: $0 [--force] init|clean"
    exit 0
}

if [ "$#" -eq 1 ]; then
    ops="$1"
elif [ "$#" -eq 2 ]; then
    if [ "$1" == '--force' ]; then
        force=1
    else
        force=0
    fi
    ops=$2
else
    help
fi

case $ops in
    init)
        init
        ;;
    clean)
        clean
        ;;
    *)
        help
esac
