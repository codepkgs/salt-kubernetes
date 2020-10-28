# 使用 `ansible` 安装 `salt master` 和 `salt minion`

[ansible 安装 salt-master 和 salt-minion](https://github.com/x-hezhang/ansible-saltstack)

# 前提

**注意：在使用前，需要修改 scripts/vars.ini，并修改字段的内容，所有字段的值不要使用引号**

执行 `scripts/main.sh` 脚本的机器要安装 `cfssl`、`cfssljson` 和 `kubectl`。

执行脚本下载 `cfssl` 、`cfssljson` 和 `kubectl`：`./main.sh download`

# 执行步骤

- 执行步骤

  ```text
  1. 将所有代码复制到 salt master 的 `file_roots` 目录下，如 `/srv/salt`。以下命令均在 salt master 上执行。
  2. 进入到 scripts 目录，先执行 ./main.sh clean，然后执行 ./main.sh init
  3. 所有K8S节点初始化。salt "*" state.apply
  4. 重启所有的K8S节点。
  5. kube-apiserver HA 部署，会在节点上安装 keepalived和nginx。
  6. 参考 master 节点执行的命令。
  7. 参考 worker 节点执行的命令。
  8. 执行 ./post.sh
  9. 执行 ./addons.sh 部署插件。
  ```

- `kube-apiserver` 高可用部署

  注意：先执行该步骤，在执行 `etcd` 和 `k8s-master` 等任务。

  ```bash
  # 需要安装keepalvied和nginx的节点执行如下操作，可在单台机器部署也可在多台机器部署，必须和kube-apiserver节点分开。
  # 默认监听的地址是 6443 端口，不要修改。
  salt "vm09.fdisk.cc" state.sls k8s-apiserver-ha
  salt "vm10.fdisk.cc" state.sls k8s-apiserver-ha
  ```

- `master` 节点执行的命令

  ```bash
  # 1. salt master 节点 或 etcd 节点安装 etcd
  # 示例
  salt "master01.fdisk.cc" state.sls etcd
  salt "master02.fdisk.cc" state.sls etcd
  salt "master03.fdisk.cc" state.sls etcd

  # 2. salt master 节点执行 k8s-master
  # 示例
  salt "master01.fdisk.cc" state.sls k8s-master
  salt "master02.fdisk.cc" state.sls k8s-master
  salt "master03.fdisk.cc" state.sls k8s-master
  ```

- `worker` 节点执行的命令

  ```bash
  # 1. salt worker 节点执行 k8s-worker
  # 示例
  salt "worker01.fdisk.cc" state.sls k8s-worker
  salt "worker02.fdisk.cc" state.sls k8s-worker
  salt "worker03.fdisk.cc" state.sls k8s-worker
  ```

- 加入 `worker` 节点

  ```bash
  salt "worker04.fdisk.cc" state.sls k8s-worker
  ```

- 部署插件

  ```bash
  1. 部署 flannel
  ./addons.sh flannel

  2. 部署 coredns
  ./addons.sh coredns

  3. 部署 metrics-server
  ./addons.sh metrics-server

  4. 部署 ingress-nginx
  ./addon.sh ingress-nginx
  ./addon.sh ingress-label <node_name>  # 给节点设置ingress的标签，否则ingress-nginx-controller的容器无法创建。
  ```

- `ingress-nginx` 高可用部署

  注意：先执行该步骤，在执行 `etcd` 和 `k8s-master` 等任务。

  ```bash
  # 需要安装keepalvied和nginx的节点执行如下操作，可在单台机器部署也可在多台机器部署，必须和kube-apiserver节点分开。
  # 可以和 kube-apiserver 高可用使用同一台机器
  # 默认监听的地址是 80和443 端口，不要修改。
  salt "vm09.fdisk.cc" state.sls k8s-ingress-nginx-ha
  salt "vm10.fdisk.cc" state.sls k8s-ingress-nginx-ha
  ```

- 其他设置

  ```bash
  1. 给 master 节点设置污点
  ./addons.sh taint-master

  2. 给 master 节点设置 label
  ./addons.sh master-lable

  3. 取消节点的 ingress 标签
  ./addons.sh undo-ingress-label
  ```

- 其他功能

  ```bash
  ./addons.sh -h
  ```
