#!/bin/bash
set -e

# 定义全局变量
k8s_master_certs_dir="../salt/base/k8s-master/files/certs"


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

    # 删除 k8s-master certs 文件
    rm -rf ${k8s_master_certs_dir}/* &> /dev/null
}

init() {
    # 产生csr文件
    python csr.py

    # 产生证书
    ca
    aggregator_ca
    etcd
    gen_sa
    apiserver
    apiserver_kubelet_client
    proxy_client_metrics_server

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
