# 前提

执行 `scripts/main.sh` 脚本的机器要安装 `openssl` 和 `kubectl`。

# 执行步骤

- 执行步骤

  ```text
  1. 将所有代码复制到 salt master 上。以下命令均在 salt master 上执行。
  2. 进入到 scripts 目录，先执行 ./main.sh clean，然后执行 ./main.sh init
  3. 所有K8S节点初始化。salt "*" state.apply
  4. 重启所有的K8S节点。
  5. 参考 master 节点执行的命令。
  6. 参考 worker 节点执行的命令。
  7. 执行 ./post.sh
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
