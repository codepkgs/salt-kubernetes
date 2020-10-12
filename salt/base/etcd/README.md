# 变量

注：`etcd` 对外监听的端口固定为 `2379`

- `etcd_data_dir`  
   定义数据目录。默认是 `/var/lib/etcd/defaults.etcd`

- `etcd_initial_cluster`  
   该参数是必选参数。不管有没有启用集群，都要定义该参数。  
   不启用集群：定义格式为 `etcd01=https://10.0.0.1:2380`，如果使用了 `https`，则要定义证书，如果是 `http`，则不用定义证书。  
   启用集群：定义格式为 `etcd01=https://10.0.100.13:2380,etcd02=https://10.0.100.14:2380,etcd03=https://10.0.100.15:2380`。要配置证书。

- `etcd_initial_cluster_token`  
   集群参数。在集群定义时，指定 `token`，默认为 `etcd_cluster`

- `etcd_initial_cluster_state`  
   集群参数。在集群定义时，指定集群初始状态。默认是 `new`

- `etcd_enable_v2`  
   是否启用 `v2` 版本的 `api`。默认是 `true`。

- `etcd_cert_file`  
   指定 `etcd` 服务器端证书。渲染后的文件名是 `/etc/etcd/certs/etcd.pem`。当使用 `https` 时，需要定义。证书的内容定义的 `pillar` 中，字段名为 `etcd_cert_content`。

- `etcd_key_file`  
   指定 `etcd` 服务器端私钥文件。渲染后的文件名是 `/etc/etcd/certs/etcd-key.pem`。当使用 `https` 时，需要定义。证书的内容定义的 `pillar` 中，字段名为 `etcd_key_content`。

- `etcd_trusted_ca_file`  
   指定 `etcd` 服务器端 CA 证书。渲染后的文件名是 `/etc/etcd/certs/ca.pem`。当使用 `https` 时，需要定义。证书的内容定义的 `pillar` 中，字段名为 `etcd_trusted_ca_content`。

- `etcd_peer_cert_file`  
   指定 `etcd` peer 端证书。渲染后的文件名是`/etc/etcd/certs/etcd-peer-cert.pem`。当使用 `https` 时，需要定义。证书的内容定义的 `pillar` 中，字段名为 `etcd_peer_cert_content`。

- `etcd_peer_key_file`  
   指定 `etcd` peer 端私钥。渲染后的文件名是`/etc/etcd/certs/etcd-peer-key.pem`。当使用 `https` 时，需要定义。证书的内容定义的 `pillar` 中，字段名为 `etcd_peer_key_content`。

- `etcd_peer_trusted_ca_file`  
   指定 `etcd` peer 端 CA 证书。渲染后的文件名是 `/etc/etcd/certs/ca-peer.pem`。当使用 `https` 时，需要定义。证书的内容定义的 `pillar` 中，字段名为 `etcd_peer_trusted_ca_content`。

- `etcd_client_cert_auth`  
   是否验证客户端证书。默认是 `true`

- `etcd_peer_client_cert_auth`  
   是否验证 peer 端证书。默认是 `true`

- `etcd_auto_tls`  
   服务器端证书是否自动签发。默认是 `false`

- `etcd_peer_auto_tls`  
   peer 端证书是否自动签发。默认是 `false`

- `etcd_listen_metrics_urls`  
   指定对外暴露 `/metrics` 和 `/health` 的地址。默认是 `http://{{ host_ip }}:2381`

# 脚本

可以直接使用 `scripts/main.sh` 产生 `etcd pillar` 文件 `etcd.sls`。所有变量定义在 `scripts/etcd_var.ini` 中。

使用前需要修改 `scripts/files` 中的 `json` 文件。
