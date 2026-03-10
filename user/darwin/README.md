# Home Manager · Darwin（macOS）

macOS 专用 Home Manager 配置现在由 `profiles/` 组合 `modules/` 下的 canonical 模块。

| 路径                                     | 说明                                                                  |
| ---------------------------------------- | --------------------------------------------------------------------- |
| `profiles/user/stella.nix`               | `stella` 的 Home Manager 组合入口                                     |
| `modules/home/base.nix`                  | `homeDirectory` / `xdg` 等基础设置                                    |
| `modules/home/core/default.nix`          | 通用 CLI、git、toolchain、Python mirror、theme                        |
| `modules/home/darwin/apps/ghostty.nix`   | Ghostty 终端配置（`~/.config/ghostty/config`）                        |
| `modules/home/darwin/shell.nix`          | Shell PATH、bash/zsh 初始化、proxy env 继承                           |
| `modules/home/darwin/services/mihomo/`   | [mihomo](https://github.com/MetaCubeX/mihomo)：包、配置、launchd      |
| `modules/home/darwin/services/openclaw/` | OpenClaw 的 package / plugins / config / secrets / runtime 子模块边界 |

`stella` 的 Home Manager 接线来自 `profiles/user/stella.nix` +
`hosts/stella/home.nix`。系统代理手动接管命令由 `modules/system/darwin/system/proxy-tools.nix`
提供（`proxy-on` / `proxy-off` /
`proxy-status`）。bash 和 zsh 会自动继承声明式 proxy 环境；需要临时清空当前 shell 时再使用
`eval "$(proxy-env-off)"`。Python 生态镜像变量由 `modules/home/core/pip.nix`
提供。Node/Python工具链统一由 `infra/toolchains.nix` 定义，pnpm 通过 Corepack 提供；不建议与 `nvm` /
`volta` 混用。`python / git / nodejs / docker / jq / curl` 在 `modules/home/core/tooling/`
按职责拆分声明；`direnv` 与 devshell helper 由 `modules/home/core/packages.nix` 管理。

## 常用命令

- 全量：`darwin-rebuild switch --flake .`
- 主机：`sudo darwin-rebuild switch --flake .#stella`
- 回滚：`sudo darwin-rebuild switch --rollback`
