#!/bin/bash

set -e

KUBECTL="kubectl --kubeconfig admin.kubeconfig"
CLUSTER_CIDR="$(grep 'pod-cidr' vars.ini | awk -F'=' '{print $2}')"
CLUSTER_DNS="$(grep 'cluster-dns' vars.ini | awk -F'=' '{print $2}')"
MASTER01="$(grep 'master_host1' vars.ini | awk -F'=' '{print $2}')"
MASTER02="$(grep 'master_host2' vars.ini | awk -F'=' '{print $2}')"
MASTER03="$(grep 'master_host3' vars.ini | awk -F'=' '{print $2}')"

deploy_flannel() {
    local addon_dir='addons/flannel'

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
    local addon_dir='addons/coredns'
    echo ""
    echo "deploy coredns ......"

    /bin/bash ${addon_dir}/deploy.sh -i $CLUSTER_DNS | $KUBECTL apply -f -
}

taint_master() {
    $KUBECTL taint nodes `$KUBECTL get node -o wide | grep "${MASTER01}" | awk '{print $1}'` node-role.kubernetes.io/master="":NoSchedule
    $KUBECTL taint nodes `$KUBECTL get node -o wide | grep "${MASTER02}" | awk '{print $1}'` node-role.kubernetes.io/master="":NoSchedule
    $KUBECTL taint nodes `$KUBECTL get node -o wide | grep "${MASTER03}" | awk '{print $1}'` node-role.kubernetes.io/master="":NoSchedule
}

master_label() {
    $KUBECTL label node `$KUBECTL get node -o wide | grep "${MASTER01}" | awk '{print $1}'` node-role.kubernetes.io/master=""
    $KUBECTL label node `$KUBECTL get node -o wide | grep "${MASTER02}" | awk '{print $1}'` node-role.kubernetes.io/master=""
    $KUBECTL label node `$KUBECTL get node -o wide | grep "${MASTER03}" | awk '{print $1}'` node-role.kubernetes.io/master=""
}

help() {
    echo "usage: $0 {flannel|coredns|taint_master|master_label}"
    exit 0
}

case $1 in
    flannel)
        deploy_flannel
        ;;
    coredns)
        deploy_coredns
        ;;
    taint_master)
        taint_master
        ;;
    master_label)
        master_label
        ;;
    *)
        help
esac
