# 共享变量（`vars/`）

所有主机共享的变量定义。

| 路径 | 说明 |
|---|---|
| `default.nix` | 用户信息（用户名、姓名、邮箱）、初始密码哈希、SSH authorized keys |
| `networking.nix` | mihomo 端口/代理 URL（需与 `user/darwin/services/mihomo/` 对齐）、DNS、主机网络、SSH knownHosts |

镜像相关配置分散在：`system/common/nix.nix`（Nix store）、`system/darwin/apps.nix`（Homebrew）、`user/common/core/pip.nix` 与 mihomo `no_proxy`（PyPI 等）。
