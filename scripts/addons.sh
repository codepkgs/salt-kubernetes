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

deploy_metrics_server() {
    local addon_dir='addons/metrics-server'
    echo
    echo "deploy metrics-server ......"

    $KUBECTL apply -f ${addon_dir}/
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
    echo "usage: $0 {flannel|coredns|metrics-server|taint-master|master-label}"
    echo -e "\t$0 flannel\t\t:部署 flannel"
    echo -e "\t$0 coredns\t\t:部署 coredns"
    echo -e "\t$0 metrics-server\t:部署 metrics-server"
    echo -e "\t$0 taint-master\t:给 master 节点设置污点"
    echo -e "\t$0 master-label\t:给 master 节点设置 label，打上 master 标签"
    exit 0
}

case $1 in
    flannel)
        deploy_flannel
        ;;
    coredns)
        deploy_coredns
        ;;
    metrics-server)
        deploy_metrics_server
        ;;
    taint-master)
        taint_master
        ;;
    master-label)
        master_label
        ;;
    *)
        help
esac
