# Home Manager · Darwin（macOS）

macOS 专用 Home Manager 配置（与 `hosts/darwin-stella/` 一起使用）。

| 路径 | 说明 |
|---|---|
| `default.nix` | 设置 `homeDirectory` / `xdg`；导入分组目录与 `../base/*` |
| `apps/gui.nix` | GUI 应用层（在 256G profile 下大多由 Homebrew 接管） |
| `profiles/shell.nix` | Shell PATH / 初始化偏好（bash、zsh） |
| `services/mihomo/` | [mihomo](https://github.com/MetaCubeX/mihomo)：包、环境变量、配置、launchd |
| `services/postgresql/` | PostgreSQL 16（Nixpkgs）：包、数据目录、launchd |

`default.nix` 保留顶层模块自动扫描，并显式导入 `apps/`、`services/`、`profiles/`，以保证结构和导入顺序稳定。
`stella` 的 Home Manager 接线来自 `hosts/darwin-stella/home.nix` + `home/darwin/`。

## 常用命令

- 全量：`darwin-rebuild switch --flake .`
- 仅 HM：`home-manager switch --flake .#stella`
- 回滚：`home-manager switch --rollback`
