base:
  "*":
    - system-init
    - ntpd
    - resolv
    - schedule

  "vm1[3-5].fdisk.cc":
    - etcd
