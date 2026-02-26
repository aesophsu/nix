# 文档索引

仓库文档入口（部署、风格、软件管理与专题说明）。

| 文档 | 说明 |
|---|---|
| `DEPLOYMENT.md` | 新机部署与重建流程（Nix + nix-darwin + Home Manager） |
| `docs/STYLE.md` | Nix 注释与配置风格约定 |
| `docs/PACKAGES.md` | 软件管理说明（系统/用户/Homebrew 例外） |
| `README.md` | 仓库总览与架构图（模块边界 + 导入关系） |
| `MIGRATION.md` | 目录重构迁移说明（旧路径 -> 新路径） |
| `docs/generated/architecture.md` | 生成的架构/输出索引 |
| `docs/generated/hosts.md` | 生成的主机清单 |
| `docs/generated/modules.md` | 生成的模块与输出索引 |
| `docs/generated/checks-and-commands.md` | 生成的 checks 矩阵与常用命令 |
| `scripts/docs/README.md` | 文档生成脚本说明 |

当前架构关键点：

- `outputs/default.nix`：单机 `stella` 的 flake 输出装配入口
- `outputs/darwin/default.nix`：Darwin 构建入口（直接组合 `system/` + `user/` + `hosts/stella/`）
- `outputs/darwin/tests/default.nix`：单主机 `stella` 的 smoke tests
- `checks.<system>.smoke-eval` / `checks.<system>.docs-sync` / `checks.<system>.pre-commit`：统一命名的检查项

目录说明见 `lib/README.md`、`system/README.md`、`user/README.md`、`overlays/README.md`、`vars/README.md`、`misc/certs/README.md`，以及 `user/darwin/services/` 下各子目录说明。
