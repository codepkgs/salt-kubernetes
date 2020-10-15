base:
  "*":
    - system-init
    - ntpd
    - docker-ce

  "vm1[3-5].fdisk.cc":
    - etcd
    - k8s-master