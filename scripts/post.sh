#!/bin/bash

# set -e

TOKEN_PUB="$(grep 'TOKEN_PUB' token.txt | awk -F'=' '{print $2}')"
TOKEN_SECRET="$(grep 'TOKEN_SECRET' token.txt | awk -F'=' '{print $2}')"
BOOTSTRAP_TOKEN="$(grep 'BOOTSTRAP_TOKEN' token.txt | awk -F'=' '{print $2}')"
CLUSTER_CIDR="$(grep 'pod-cidr' vars.ini | awk -F'=' '{print $2}')"
CLUSTER_DNS="$(grep 'cluster-dns' vars.ini | awk -F'=' '{print $2}')"

KUBECTL="kubectl --kubeconfig admin.kubeconfig"

kubelet_bootstrap_token_apply() {
    echo ""
    echo "apply kubelet-bootstrap token ......"
    if ! $KUBECTL -n kube-system get secret bootstrap-token-${TOKEN_PUB} &> /dev/null; then
        $KUBECTL -n kube-system create secret generic bootstrap-token-${TOKEN_PUB} \
            --type 'bootstrap.kubernetes.io/token' \
            --from-literal description="kubelet-bootstrap-token" \
            --from-literal token-id=${TOKEN_PUB} \
            --from-literal token-secret=${TOKEN_SECRET} \
            --from-literal usage-bootstrap-authentication=true \
            --from-literal usage-bootstrap-signing=true
    else
        echo "apply kubelet-bootstrap token: pass"
    fi
}

kubelet_bootstrap_csr_cmd() {
    cat << EOF | kubectl --kubeconfig admin.kubeconfig apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubelet-bootstrap
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:node-bootstrapper
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:bootstrappers
EOF
}

kubelet_bootstrap_csr_approve_cmd() {
    cat << EOF | kubectl --kubeconfig admin.kubeconfig apply -f -
# Approve all CSRs for the group "system:bootstrappers"
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: auto-approve-csrs-for-group
subjects:
- kind: Group
  name: system:bootstrappers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
  apiGroup: rbac.authorization.k8s.io
---
# To let a node of the group "system:nodes" renew its own credentials
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: node-client-cert-renewal
subjects:
- kind: Group
  name: system:nodes
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
  apiGroup: rbac.authorization.k8s.io
EOF
}

deploy_flannel() {
    echo ""
    echo "deploy flannel ......"
    # 替换flannel 文件
    sed -i.bak "/Network/s#10.244.0.0/16#${CLUSTER_CIDR}#" files/kube-flannel.yaml

    # 部署flannel
    $KUBECTL apply -f files/kube-flannel.yaml

    # 删除bak文件
    sed -i.bak "/Network/s#${CLUSTER_CIDR}#10.244.0.0/16#" files/kube-flannel.yaml
    rm -rf files/kube-flannel.yaml.bak &> /dev/null
}

deploy_coredns() {
    echo ""
    echo "deploy coredns ......"

    /bin/bash coredns/deploy.sh -i $CLUSTER_DNS | $KUBECTL apply -f -
}

# 执行
kubelet_bootstrap_token_apply
kubelet_bootstrap_csr_cmd
kubelet_bootstrap_csr_approve_cmd

# 部署 coredns
deploy_coredns

# 部署flannel
deploy_flannel
