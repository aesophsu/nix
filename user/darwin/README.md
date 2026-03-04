# Home Manager · Darwin（macOS）

macOS 专用 Home Manager 配置（与 `hosts/stella/` 一起使用）。

| 路径 | 说明 |
|---|---|
| `default.nix` | 设置 `homeDirectory` / `xdg`；自动扫描并导入当前目录模块 |
| `profiles/shell.nix` | Shell PATH / 初始化偏好（bash、zsh） |
| `services/mihomo/` | [mihomo](https://github.com/MetaCubeX/mihomo)：包、通用 CLI 代理变量、配置、launchd |

`default.nix` 使用顶层模块自动扫描，当前主要由 `profiles/` 与 `services/` 组成。
系统代理默认行为与开关命令由 `system/darwin/system.nix` 提供（`proxy-on` / `proxy-off` / `proxy-status`）。
Python 生态镜像变量由 `user/common/core/pip.nix` 提供；通用 HTTP(S)_PROXY 由 `services/mihomo/` 统一注入。
`stella` 的 Home Manager 接线来自 `hosts/stella/home.nix` + `user/darwin/`。

## 常用命令

- 全量：`darwin-rebuild switch --flake .`
- 仅 HM：`home-manager switch --flake .#stella`
- 回滚：`home-manager switch --rollback`
