base:
  "*":
    - system-init
    - ntpd
    - schedule

  "vm1[3-5].fdisk.cc":
    - etcd
    - k8s-master
