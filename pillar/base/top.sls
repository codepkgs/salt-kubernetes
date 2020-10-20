base:
  "*":
    - system-init
    - ntpd
    - etcd
    - k8s-apiserver-ha
    - k8s-ingress-nginx-ha
    - k8s-master
    - k8s-worker
