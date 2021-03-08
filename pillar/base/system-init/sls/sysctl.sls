sysctl_configs:
  - key: net.core.somaxconn
    value: 65535
  - key: net.ipv4.tcp_max_syn_backlog
    value: 262144
  - key: net.ipv4.tcp_syncookies
    value: 1
  - key: net.ipv4.tcp_max_tw_buckets
    value: 262144
  - key: net.core.netdev_max_backlog
    value: 262144
  - key: net.ipv4.ip_local_port_range
    value: 1024 65000
  - key: net.ipv4.tcp_tw_reuse
    value: 1
  - key: net.ipv4.tcp_tw_recycle
    value: 0
  - key: net.ipv4.tcp_timestamps
    value: 0
  - key: net.ipv4.tcp_synack_retries
    value: 2
  - key: net.ipv4.tcp_fin_timeout
    value: 1
  - key: net.ipv4.tcp_keepalive_time
    value: 600
  - key: net.ipv4.tcp_keepalive_intvl
    value: 30
  - key: net.ipv4.tcp_keepalive_probes
    value: 3
  - key: net.ipv6.conf.all.disable_ipv6 
    value: 1
  - key: net.ipv6.conf.default.disable_ipv6
    value: 1
  - key: net.ipv6.conf.lo.disable_ipv6
    value: 1
  - key: net.ipv4.neigh.default.gc_stale_time
    value: 120
  - key: net.ipv4.conf.all.rp_filter
    value: 0
  - key: net.ipv4.conf.default.rp_filter
    value: 0
  - key: net.ipv4.conf.default.arp_announce
    value: 2
  - key: net.ipv4.conf.lo.arp_announce
    value: 2
  - key: net.ipv4.conf.all.arp_announce
    value: 2
  - key: net.netfilter.nf_conntrack_max
    value: 2310720
  - key: fs.inotify.max_user_watches
    value: 1048576
  - key: fs.inotify.max_user_instances
    value: 8192
  - key: vm.swappiness
    value: 0
  - key: net.ipv4.ip_forward
    value: 1
  - key: vm.overcommit_memory
    value: 1
  - key: vm.panic_on_oom
    value: 0