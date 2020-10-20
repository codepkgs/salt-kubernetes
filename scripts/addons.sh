#!/bin/bash

set -e

KUBECTL="kubectl --kubeconfig admin.kubeconfig"
CLUSTER_CIDR="$(grep 'pod-cidr' vars.ini | awk -F'=' '{print $2}')"
CLUSTER_DNS="$(grep 'cluster-dns' vars.ini | awk -F'=' '{print $2}')"
MASTER_COUNTS="$(grep 'master_counts' vars.ini | awk -F'=' '{print $2}')"

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

deploy_ingress_nginx() {
    local addon_dir='addons/ingress-nginx'
    echo
    echo "deploy ingress-nginx ......"

    $KUBECTL apply -f ${addon_dir}/ingress-nginx-deploy.yaml

    echo "then invoke command to set label <ingress: true> for node"
    echo "set label command: $0 ingress-label <node_name>"
}

taint_master() {
    for i in `seq 1 ${MASTER_COUNTS}`
    do
        local MASTER=$(grep "master_host$i" vars.ini | awk -F'=' '{print $2}')
        $KUBECTL taint nodes `$KUBECTL get node -o wide | grep "${MASTER}" | awk '{print $1}'` node-role.kubernetes.io/master="":NoSchedule
    done
}

master_label() {
    for i in `seq 1 ${MASTER_COUNTS}`
    do
        local MASTER=$(grep "master_host$i" vars.ini | awk -F'=' '{print $2}')
        $KUBECTL label node `$KUBECTL get node -o wide | grep "${MASTER}" | awk '{print $1}'` node-role.kubernetes.io/master=""
    done
}

ingress_label() {
    local ops=$1
    local node=$2
    if [ -n "$node" ]; then
        if [ "$ops" == 'do' ]; then
            $KUBECTL label node $node ingress=true
        elif [ "$ops" == 'undo' ]; then
            $KUBECTL label node $node ingress-
        fi
    else
        echo "please specify the node name!"
        exit 0
    fi
}

help() {
    echo "usage:"
    echo -e "\t$0 {flannel|coredns|metrics-server|ingress-nginx|taint-master|master-label|ingress-label|undo-ingress-label}"
    echo
    echo "summary:"
    echo -e "\t$0 flannel\t\t\t\t:部署 flannel"
    echo -e "\t$0 coredns\t\t\t\t:部署 coredns"
    echo -e "\t$0 metrics-server\t\t\t:部署 metrics-server"
    echo -e "\t$0 ingress-nginx\t\t\t:部署 ingress-nginx"
    echo -e "\t$0 taint-master\t\t\t:给 master 节点设置污点"
    echo -e "\t$0 master-label\t\t\t:给 master 节点设置 label，打上 master 标签"
    echo -e "\t$0 ingress-label <node_name>\t\t:给节点设置 ingress:true 的标签，否则 ingress-nginx-controller 无法创建"
    echo -e "\t$0 undo-ingress-label <node_name>\t:删除节点的 ingress:true 的标签，会删除 ingress-nginx-controller 容器"
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
    ingress-nginx)
        deploy_ingress_nginx
        ;;
    ingress-label)
        ingress_label do $2
        ;;
    undo-ingress-label)
        ingress_label undo $2
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
