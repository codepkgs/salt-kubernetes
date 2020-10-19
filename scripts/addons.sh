#!/bin/bash

set -e

KUBECTL="kubectl --kubeconfig admin.kubeconfig"
CLUSTER_CIDR="$(grep 'pod-cidr' vars.ini | awk -F'=' '{print $2}')"
CLUSTER_DNS="$(grep 'cluster-dns' vars.ini | awk -F'=' '{print $2}')"

deploy_flannel() {
    local addon_dir='files/addons/flannel'

    echo ""
    echo "deploy flannel ......"
    # 替换flannel 文件
    sed -i.bak "/Network/s#10.244.0.0/16#${CLUSTER_CIDR}#" ${addon_dir}/kube-flannel.yaml

    # 部署flannel
    $KUBECTL apply -f ${addon_dir}/kube-flannel.yaml

    # 删除bak文件
    sed -i.bak "/Network/s#${CLUSTER_CIDR}#10.244.0.0/16#" ${addon_dir}/kube-flannel.yaml
    rm -rf files/kube-flannel.yaml.bak &> /dev/null
}

deploy_coredns() {
    echo ""
    echo "deploy coredns ......"

    /bin/bash coredns/deploy.sh -i $CLUSTER_DNS | $KUBECTL apply -f -
}

help() {
    echo "usage: $0 {flannel|coredns}"
    exit 0
}

case $ops in
    flannel)
        deploy_flannel
        ;;
    coredns)
        deploy_coredns
        ;;
    *)
        help
esac
