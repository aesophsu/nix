# Home Manager · Darwin（macOS）

macOS 专用 Home Manager 配置，与 `hosts/darwin-stella` 配合使用。

## 目录结构

| 路径 | 说明 |
|------|------|
| `default.nix` | 入口：设置 `homeDirectory`、`xdg.enable`，并导入 `../base` 与当前目录下所有模块 |
| `shell.nix` | 开发/临时 shell 环境 |
| **mihomo/** | [mihomo](https://github.com/MetaCubeX/mihomo) 代理：包、环境变量、config 与 launchd |
| **openclaw/** | [OpenClaw](https://openclaw.ai)（nix-openclaw）：声明式配置、Gateway、launchd、documents |
| **postgresql/** | PostgreSQL 16（Nixpkgs）：包、数据目录与 launchd 服务 |

## 加载方式

- `default.nix` 通过 `mylib.scanPaths ./.** 自动导入本目录下所有 `.nix` 文件与子目录（每个子目录加载其 `default.nix`）。
- 与 `outputs/aarch64-darwin/src/stella.nix` 中的 `home-modules` 一致：`hosts/darwin-stella/home.nix`、`home/darwin`、`nix-openclaw.homeManagerModules.openclaw`。

## 常用命令

```bash
# 应用整机配置（含 Home Manager）
darwin-rebuild switch --flake .

# 仅应用 Home Manager（配置名 stella，对应用户见 vars/default.nix）
home-manager switch --flake .#stella

# 回滚
home-manager switch --rollback
```
