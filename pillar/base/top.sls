base:
  "*":
    - system-init
    - ntpd
    - schedule

  "vm1[3-5].fdisk.cc":
    - etcd
    - k8s-master
    - k8s-worker

  {# "vm1[6-7].fdisk.cc"
    - k8s-worker #}
