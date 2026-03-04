# 共享变量（`vars/`）

所有主机共享的变量定义。

| 路径 | 说明 |
|---|---|
| `default.nix` | 用户信息（用户名、姓名、邮箱）、初始密码哈希、SSH authorized keys |
| `networking/` | 网络配置聚合目录（proxy/mihomo/dns/hosts/ssh） |
| `toolchains.nix` | Node/Python 版本单一来源（`node.package`、`python.package`） |

代理策略单一来源为 `vars/networking/proxy.nix` 的 `proxy.policy`：

- `systemDefault`：系统代理默认状态（`on`/`off`）
- `cliDefault`：是否默认注入 CLI 代理环境变量
- `homebrewEnv`：是否在 activation 为 Homebrew 注入代理环境变量

镜像相关配置位于：`system/common/nix.nix`（Nix store）、`user/common/core/pip.nix`（PyPI/uv）。

工具链版本统一来源为 `vars/toolchains.nix`：

- `node.package = "nodejs_22"`
- `python.package = "python312"`

这些版本会被 `user/common/core/tooling/toolchain.nix` 消费，用于统一 Python/Node 工具链包。

关键目录采用显式导入清单：

- `system/darwin/.imports.nix`
- `user/common/core/.imports.nix`
