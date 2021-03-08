#!/bin/bash
set -e

# 定义全局变量
k8s_master_certs_dir="../salt/base/k8s-master/files/certs"
k8s_worker_certs_dir="../salt/base/k8s-worker/files/certs"
k8s_master_kubeconfig_dir="../salt/base/k8s-master/files/kubeconfig"
k8s_worker_kubeconfig_dir="../salt/base/k8s-worker/files/kubeconfig"
vip_address="$(grep '\<vip\>' vars.ini | awk -F'=' '{print $2}' | awk '{print $1}')"
version='1.16.9'


download() {
    echo 
    echo "download ......."
    local platform=$(uname)
    echo "platform: $platform"
    local download_url='https://devops.maka.im/kubernetes'
    if [ "$platform" == 'Darwin' ]; then
        if [ ! -d "$HOME/bin" ]; then
            mkdir ~/bin
        fi

        if [ ! -f "$HOME/bin/cfssl" ]; then
            wget $download_url/cfssl/mac/cfssl -O ~/bin/cfssl
        fi

        if [ ! -f "$HOME/bin/cfssljson" ]; then
            wget $download_url/cfssl/mac/cfssljson -O ~/bin/cfssljson
        fi

        if [ ! -f "$HOME/bin/kubectl" ]; then
            wget $download_url/v${version}/bin/kubectl_mac -O ~/bin/kubectl
        fi

        chmod +x $HOME/bin/cfssl $HOME/bin/cfssljson $HOME/bin/kubectl
    elif [ "$platform" == 'Linux' ]; then
        if [ ! -f "/usr/local/bin/cfssl" ]; then
            wget $download_url/cfssl/linux/cfssl -O /usr/local/bin/cfssl
        fi

        if [ ! -f "/usr/local/bin/cfssljson" ]; then
            wget $download_url/cfssl/linux/cfssljson -O /usr/local/bin/cfssljson
        fi

        if [ ! -f "/usr/local/bin/kubectl" ]; then
            wget $download_url/v${version}/bin/kubectl -O /usr/local/bin/kubectl
        fi

        chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson /usr/local/bin/kubectl
    fi
}

clean() {
    # 删除certs目录下的所有内容
    rm -rf certs/* &> /dev/null

    # 删除 ha pillar 数据
    rm -rf k8s-apiserver-ha.sls ../pillar/base/k8s-ha/sls/k8s-apiserver-ha.sls &> /dev/null
    rm -rf k8s-ingress-nginx.sls ../pillar/base/k8s-ingress-nginx-ha/sls/k8s-ingress-nginx.sls &> /dev/null
    # 删除 etcd pillar 数据
    rm -rf etcd.sls ../pillar/base/etcd/sls/etcd.sls &> /dev/null
    rm -rf k8s-master.sls ../pillar/base/k8s-master/sls/k8s-master.sls &> /dev/null
    rm -rf k8s-worker.sls ../pillar/base/k8s-worker/sls/k8s-worker.sls &> /dev/null
    
    # 删除 csr json 文件
    rm -rf files/ca-csr.json &> /dev/null
    rm -rf files/etcd-csr.json &> /dev/null
    rm -rf files/kube-apiserver-csr.json &> /dev/null
    rm -rf files/aggregator-ca-csr.json &> /dev/null
    rm -rf files/apiserver-kubelet-client-csr.json &> /dev/null
    rm -rf files/proxy-client-csr.json &> /dev/null
    rm -rf files/kube-controller-manager-csr.json &> /dev/null
    rm -rf files/kube-scheduler-csr.json &> /dev/null
    rm -rf files/k8s-admin-csr.json &> /dev/null
    rm -rf files/kube-proxy-csr.json &> /dev/null

    rm -rf admin.kubeconfig &> /dev/null

    # 删除 k8s-master 文件
    rm -rf ${k8s_master_certs_dir}/* &> /dev/null
    rm -rf ${k8s_master_kubeconfig_dir}/* &> /dev/null

    # 删除 k8s-worker 文件
    rm -rf ${k8s_worker_certs_dir}/* &> /dev/null
    rm -rf ${k8s_worker_kubeconfig_dir}/* &> /dev/null

    # 删除 token
    rm -rf token.txt &> /dev/null
}

init() {
    local master_kubeconfig_dir='../salt/base/k8s-master/files/kubeconfig/'
    local worker_kubeconfig_dir='../salt/base/k8s-worker/files/kubeconfig/'

    # 创建目录结构
    if [ ! -d "certs/k8s-master" ]; then
        mkdir -p certs/k8s-master
    fi

    if [ ! -d "certs/k8s-worker" ]; then
        mkdir -p certs/k8s-worker
    fi

    if [ ! -d "$master_kubeconfig_dir" ]; then
        mkdir -p $master_kubeconfig_dir
    fi

    if [ ! -d "$worker_kubeconfig_dir" ]; then
        mkdir -p $worker_kubeconfig_dir
    fi

    # 产生csr文件
    python csr.py

    # 产生证书
    ca
    aggregator_ca
    etcd
    gen_sa
    apiserver
    controller_manager
    scheduler
    apiserver_kubelet_client
    proxy_client_metrics_server
    k8s_admin
    kube_proxy

    # kubeconfig
    controller_manager_kubeconfig
    scheduler_kubeconfig
    kubeadmin_kubeconfig

    # mv kubeconfig
    mv kube-controller-manager.kubeconfig $master_kubeconfig_dir
    mv kube-scheduler.kubeconfig $master_kubeconfig_dir
    cp admin.kubeconfig $master_kubeconfig_dir

    # 复制证书
    if [ ! -d ${k8s_master_certs_dir} ]; then
        mkdir ${k8s_master_certs_dir}
    fi
    cp -a ./certs/ca* ../salt/base/k8s-master/files/certs/
    cp -a ./certs/sa.* ../salt/base/k8s-master/files/certs/
    cp -a ./certs/aggregator-ca* ../salt/base/k8s-master/files/certs/
    cp -a ./certs/k8s-master/* ../salt/base/k8s-master/files/certs/

    if [ ! -d ${k8s_worker_certs_dir} ]; then
        mkdir ${k8s_worker_certs_dir}
    fi
    cp -a ./certs/ca.pem ./certs/k8s-worker/
    cp -a ./certs/k8s-worker/* ../salt/base/k8s-worker/files/certs/

    # 创建目录
    if [ ! -d ${k8s_master_kubeconfig_dir} ]; then
        mkdir ${k8s_master_kubeconfig_dir}
    fi
    if [ ! -d ${k8s_worker_kubeconfig_dir} ]; then
        mkdir ${k8s_worker_kubeconfig_dir}
    fi
    
    # 产生 pillar 数据
    python pillar.py
    mkdir -p ../pillar/base/k8s-apiserver-ha/sls/ ../pillar/base/k8s-ingress-nginx-ha/sls/ &> /dev/null
    mkdir -p ../pillar/base/etcd/sls/ ../pillar/base/k8s-master/sls/ ../pillar/base/k8s-worker/sls/ &> /dev/null

    mv k8s-apiserver-ha.sls ../pillar/base/k8s-apiserver-ha/sls/
    mv k8s-ingress-nginx.sls ../pillar/base/k8s-ingress-nginx-ha/sls/
    mv etcd.sls ../pillar/base/etcd/sls/
    mv k8s-master.sls ../pillar/base/k8s-master/sls/ &> /dev/null
    mv k8s-worker.sls ../pillar/base/k8s-worker/sls/ &> /dev/null

    # kubelet
    kubelet_bootstrap_token
    kubelet_bootstrap_kubeconfig

    mv kubelet-bootstrap.kubeconfig $worker_kubeconfig_dir/

    # kube-proxy
    kubeproxy_kubeconfig
    mv kube-proxy.kubeconfig $worker_kubeconfig_dir/
}

gen_cert() {
    cert_path=$1
    cert_name=$2
    csr_json=$3

    if [ ! -f "./certs/ca.pem" -o ! -f "./certs/ca-key.pem" ]; then
        ca
    fi

    if [ "$force" == "1" ]; then
        cfssl gencert -ca ./certs/ca.pem -ca-key ./certs/ca-key.pem \
            -config ./files/config.json -profile peer \
            ./files/${csr_json} | cfssljson -bare ${cert_path}/${cert_name}
        rm -rf ${cert_path}/${cert_name}.csr &> /dev/null
    elif [ ! -f "${cert_path}/${cert_name}.pem" ]; then
        cfssl gencert -ca ./certs/ca.pem -ca-key ./certs/ca-key.pem \
            -config ./files/config.json -profile peer \
            ./files/${csr_json} | cfssljson -bare ${cert_path}/${cert_name}
        rm -rf ${cert_path}/${cert_name}.csr &> /dev/null
    else
        echo "warning: ${cert_path}/${cert_name}.pem cert is exist now, if you want to generate, please use --force"
    fi
}

gen_cert_aggregator() {
    cert_path=$1
    cert_name=$2
    csr_json=$3

    if [ ! -f "./certs/ca.pem" -o ! -f "./certs/ca-key.pem" ]; then
        ca
    fi

    if [ "$force" == "1" ]; then
        cfssl gencert -ca ./certs/aggregator-ca.pem -ca-key ./certs/aggregator-ca-key.pem \
            -config ./files/config.json -profile peer \
            ./files/${csr_json} | cfssljson -bare ${cert_path}/${cert_name}
        rm -rf ${cert_path}/${cert_name}.csr &> /dev/null
    elif [ ! -f "${cert_path}/${cert_name}.pem" ]; then
        cfssl gencert -ca ./certs/aggregator-ca.pem -ca-key ./certs/aggregator-ca-key.pem \
            -config ./files/config.json -profile peer \
            ./files/${csr_json} | cfssljson -bare ${cert_path}/${cert_name}
        rm -rf ${cert_path}/${cert_name}.csr &> /dev/null
    else
        echo "warning: ${cert_path}/${cert_name}.pem cert is exist now, if you want to generate, please use --force"
    fi
}

gen_kubeconfig() {
    api_server=$1
    cert_path=$2
    kubeconfig_filename=$3
    user=$4

    # 1. 设置集群参数
    kubectl config set-cluster kubernetes \
        --certificate-authority=./certs/ca.pem \
        --embed-certs=true \
        --server=${api_server} \
        --kubeconfig=${kubeconfig_filename}

    # 2. 设置客户端认证参数
    kubectl config set-credentials ${user} \
        --embed-certs=true \
        --client-certificate=${cert_path}.pem \
        --client-key=${cert_path}-key.pem \
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

    echo ""
    echo "generate ca certs ......"

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

    echo ""
    echo "generate aggregator_ca certs ......"

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
    local cert_path='certs/k8s-master'
    local cert_name='etcd'
    local csr_json='etcd-csr.json'
    echo ""
    echo "generate etcd certs ......"
    gen_cert $cert_path $cert_name $csr_json
}

gen_sa() {
    local cert_name='sa'
    echo ""
    echo "generate sa keys ......"
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
    local cert_path='certs/k8s-master'
    local cert_name='kube-apiserver'
    local csr_json='kube-apiserver-csr.json'
    echo ""
    echo "generate apiserver certs ......"
    gen_cert $cert_path $cert_name $csr_json
}

controller_manager() {
    local cert_path='certs/k8s-master'
    local cert_name='kube-controller-manager'
    local csr_json='kube-controller-manager-csr.json'
    echo ""
    echo "generate controller_manager certs ......"
    gen_cert $cert_path $cert_name $csr_json
}

scheduler() {
    local cert_path='certs/k8s-master'
    local cert_name='kube-scheduler'
    local csr_json='kube-scheduler-csr.json'
    echo ""
    echo "generate scheduler certs ......"
    gen_cert $cert_path $cert_name $csr_json
}

apiserver_kubelet_client() {
    local cert_path='certs/k8s-master'
    local cert_name='apiserver-kubelet-client'
    local csr_json='apiserver-kubelet-client-csr.json'
    echo ""
    echo "generate apiserver_kubelet_client certs ......"
    gen_cert $cert_path $cert_name $csr_json
}

proxy_client_metrics_server() {
    local cert_path='certs/k8s-master'
    local cert_name='proxy-client'
    local csr_json='proxy-client-csr.json'
    echo ""
    echo "generate proxy_client certs ......"
    gen_cert_aggregator $cert_path $cert_name $csr_json
}

k8s_admin() {
    local cert_path='certs/k8s-master'
    local cert_name='k8s-admin'
    local csr_json='k8s-admin-csr.json'
    echo ""
    echo "generate k8s-admin certs ......"
    gen_cert $cert_path $cert_name $csr_json
}

kube_proxy() {
    local cert_path='certs/k8s-worker'
    local cert_name='kube-proxy'
    local csr_json='kube-proxy-csr.json'
    echo ""
    echo "generate kube-proxy certs ......"
    gen_cert $cert_path $cert_name $csr_json
}

controller_manager_kubeconfig() {
    local vip="https://$vip_address:6443"
    local cert_path='certs/k8s-master/kube-controller-manager'
    echo ""
    echo "generate controller_manager kubeconfig ......"
    gen_kubeconfig ${vip} ${cert_path} kube-controller-manager.kubeconfig system:kube-controller-manager
}

scheduler_kubeconfig() {
    local vip="https://$vip_address:6443"
    local cert_path='certs/k8s-master/kube-scheduler'
    echo ""
    echo "generate scheduler kubeconfig ......"
    gen_kubeconfig ${vip} ${cert_path} kube-scheduler.kubeconfig system:kube-scheduler
}

kubeadmin_kubeconfig() {
    local vip="https://$vip_address:6443"
    local cert_path='certs/k8s-master/k8s-admin'
    echo ""
    echo "generate kube-admin kubeconfig ......"
    gen_kubeconfig ${vip} ${cert_path} admin.kubeconfig kubernetes-admin
}

kubeproxy_kubeconfig() {
    local vip="https://$vip_address:6443"
    local cert_path='certs/k8s-worker/kube-proxy'
    echo ""
    echo "generate kube-proxy kubeconfig ......"
    gen_kubeconfig ${vip} ${cert_path} kube-proxy.kubeconfig system:kube-proxy
}

kubelet_bootstrap_token() {
    local TOKEN_PUB=$(openssl rand -hex 3)
    local TOKEN_SECRET=$(openssl rand -hex 8)
    local BOOTSTRAP_TOKEN="${TOKEN_PUB}.${TOKEN_SECRET}"
    local token_file="token.txt"
    if [ ! -f "$token_file" ]; then
        echo "TOKEN_PUB=${TOKEN_PUB}" > ${token_file}
        echo "TOKEN_SECRET=${TOKEN_SECRET}" >> ${token_file}
        echo "BOOTSTRAP_TOKEN=${BOOTSTRAP_TOKEN}" >> ${token_file}
    fi
}

kubelet_bootstrap_kubeconfig() {
    local vip="https://$vip_address:6443"
    local BOOTSTRAP_TOKEN="$(grep 'BOOTSTRAP_TOKEN' token.txt | awk -F'=' '{print $2}')"
    echo ""
    echo "generate kubelet-bootstrap kubeconfig ......"
    # 设置集群参数
    kubectl config set-cluster kubernetes \
        --certificate-authority=./certs/ca.pem \
        --server=${vip} \
        --embed-certs=true \
        --kubeconfig=kubelet-bootstrap.kubeconfig

    # 设置客户端认证参数
    kubectl config set-credentials kubelet-bootstrap \
        --token=${BOOTSTRAP_TOKEN} \
        --kubeconfig=kubelet-bootstrap.kubeconfig

    # 设置上下文参数
    kubectl config set-context kubelet-bootstrap  \
        --cluster=kubernetes \
        --user=kubelet-bootstrap \
        --kubeconfig=kubelet-bootstrap.kubeconfig

    # 设置默认上下文
    kubectl config use-context kubelet-bootstrap --kubeconfig=kubelet-bootstrap.kubeconfig
}

help() {
    echo "usage: $0 [--force] {download|init|clean}"
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
    download)
        download
        ;;
    init)
        init
        ;;
    clean)
        clean
        ;;
    *)
        help
esac
