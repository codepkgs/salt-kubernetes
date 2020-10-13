base:
  "*":
    - system-init
    - ntpd
    - resolv
    - docker-ce

  "vm1[3-5].fdisk.cc":
    - etcd