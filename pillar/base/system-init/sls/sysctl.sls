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
    value: 30