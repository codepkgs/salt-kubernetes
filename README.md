# 前提

执行 `scripts/main.sh` 脚本的机器要安装 `openssl` 和 `kubectl`。

# 执行步骤

```text
1. 将所有代码复制到 salt master 上。
2. 修改 salt/base/top.sls 和 pillar/base/top.sls
3. 进入到 scripts 目录。
4. 执行 ./main.sh clean
5. 执行 ./main.sh init
6. 执行 ./post.sh
```
