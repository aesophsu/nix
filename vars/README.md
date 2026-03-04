# 共享变量（`vars/`）

所有主机共享的变量定义。

| 路径 | 说明 |
|---|---|
| `default.nix` | 用户信息（用户名、姓名、邮箱）、初始密码哈希、SSH authorized keys |
| `networking.nix` | mihomo 端口/代理 URL、代理策略开关（`proxy.policy.*`）、DNS、主机网络、SSH knownHosts |

代理策略单一来源为 `vars/networking.nix` 的 `proxy.policy`：

- `systemDefault`：系统代理默认状态（`on`/`off`）
- `cliDefault`：是否默认注入 CLI 代理环境变量
- `homebrewEnv`：是否在 activation 为 Homebrew 注入代理环境变量

镜像相关配置位于：`system/common/nix.nix`（Nix store）、`user/common/core/pip.nix`（PyPI/uv）。
