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
| `docs/generated/hosts.md` | 生成的主机注册表清单 |
| `docs/generated/modules.md` | 生成的模块与输出索引 |
| `docs/generated/checks-and-commands.md` | 生成的 checks 矩阵与常用命令 |
| `docs/NIXOS_ISO_REMOTE_BUILD.md` | 远程 Linux 构建 NixOS ISO（上传当前工作区） |
| `docs/NIXOS_SHAKA_INSTALL_MBP112.md` | 兼容入口：已迁移到 `nixos-installer/README.md` 的安装文档 |
| `nixos-installer/README.md` | MBP11,2 手动安装器（bootstrap 子flake）主文档 |
| `secrets/README.md` | agenix secrets 接口层（私有仓库优先 + 本地 fallback） |
| `scripts/docs/README.md` | 文档生成脚本说明 |

当前架构关键点：

- `hosts/registry.nix`：主机与系统编排的单一来源（SSOT）
- `outputs/<system>/fragments/hosts.nix`：通用 host loader fragment（按 registry 生成配置）
- `outputs/<system>/tests/default.nix`：按 registry 驱动的 smoke tests
- `checks.<system>.smoke-eval` / `checks.<system>.docs-sync` / `checks.<system>.pre-commit`：统一命名的检查项
- `nixos-installer/`：独立 bootstrap 子flake（MBP11,2 手动安装 ISO）
- `secrets/`：agenix 接口层（私有 repo 优先 + 本地 fallback）
- 从 macOS 构建 NixOS ISO 的推荐路径：`scripts/iso/build-remote.sh`（配合 `--flake-subpath nixos-installer`）

目录说明见 `lib/README.md`、`modules/README.md`、`home/README.md`、`overlays/README.md`、`vars/README.md`、`misc/certs/README.md`，以及 `home/darwin/services/` 下各子目录说明。
