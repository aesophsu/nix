# Nix 配置仓库（macOS / nix-darwin / Home Manager）

本仓库用于管理我的 macOS（当前主机 `stella`，MacBook Air M4）系统配置、用户环境与服务配置。

## 仓库架构图（概要）

```mermaid
flowchart TD
  F["`flake.nix`"] --> O["`outputs/`"]
  O --> OD["`outputs/default.nix` (单机 stella 装配)"]
  OD --> DS["`outputs/darwin/`"]
  OD --> DI["`docInventory` (单机元数据)"]

  DS --> DST["`tests/default.nix` (Darwin smoke tests)"]
  DS --> HOST["`hosts/stella/` (主机差异)"]
  DS --> M["`system/` (系统层, nix-darwin)"]
  DS --> H["`user/` (用户层, Home Manager)"]
  OD --> V["`vars/` (共享变量)"]
  OD --> OL["`outputs/lib/` (检查 helper)"]
  OD --> L["`lib/` (组装与辅助函数)"]

  M --> MB["`system/common/` (跨平台基础模块)"]
  M --> MD["`system/darwin/` (macOS 系统模块)"]
  MD --> MDM["`system/darwin/maintenance/`"]
  MD --> MDP["`system/darwin/profiles/`"]

  H --> HB["`user/common/` (跨平台用户配置)"]
  H --> HD["`user/darwin/` (macOS 用户配置)"]
  HD --> HDA["`user/darwin/apps/`"]
  HD --> HDS["`user/darwin/services/`"]
  HD --> HDP["`user/darwin/profiles/`"]

  HOST --> HOSTS["`system.nix` (系统层主机差异)"]
  HOST --> HOSTH["`home.nix` (用户层主机差异)"]
```

详细结构索引与主机/模块清单改为生成文档维护（见 `docs/generated/`）。

## 分层约定

| 层级 | 路径 | 说明 |
|---|---|---|
| 系统共享 | `system/common/` | 跨平台系统模块（Nix、用户、安全、系统级包等） |
| 系统 macOS | `system/darwin/` | `nix-darwin` 模块（Homebrew、macOS defaults、维护任务、存储 profile） |
| 用户共享 | `user/common/` | 跨平台 Home Manager 配置（CLI、语言栈、主题、shell 等） |
| 用户 macOS | `user/darwin/` | macOS 专用 Home Manager 配置（apps/services/profiles） |
| 主机差异 | `hosts/stella/` | 仅放 `stella` 独有配置（系统身份与少量 host-only 用户差异） |
| 共享变量 | `vars/` | 用户信息、网络、SSH 等共享变量 |
| 输出 helper | `outputs/lib/` | smoke check 与 pre-commit checks helper |
| 辅助函数 | `lib/` | `macosSystem`、路径与扫描工具等（已移除 host registry 抽象） |

## 文档入口

| 文档 | 说明 |
|---|---|
| `docs/README.md` | 文档总索引 |
| `docs/generated/architecture.md` | 生成的架构/输出索引（由 `scripts/docs/generate.py` 维护） |
| `docs/generated/hosts.md` | 生成的主机清单（来自 `.#docInventory`） |
| `docs/generated/modules.md` | 生成的模块与 outputs 目录索引 |
| `docs/generated/checks-and-commands.md` | 生成的 checks 矩阵与常用命令 |
| `DEPLOYMENT.md` | 部署流程（新机安装 / 重建） |
| `MIGRATION.md` | 目录重构迁移说明（旧路径 -> 新路径） |
| `system/README.md` | 系统模块结构说明 |
| `user/README.md` | Home Manager 结构说明 |
| `hosts/stella/README.md` | 主机差异边界说明 |

## 使用

```bash
darwin-rebuild switch --flake /Users/sue/Code/nix#stella
```

说明：本仓库大量使用 flake + Git 跟踪文件。新增目录或重命名文件后，请先 `git add`，否则 `.#stella` 评估可能看不到新文件。

## 检查与验证（统一命名）

```bash
# 只做评估检查（不构建系统）
nix flake check --no-build

# Smoke eval checks（Darwin）
nix build --no-link .#checks.aarch64-darwin.smoke-eval

# Docs sync
nix build --no-link .#checks.aarch64-darwin.docs-sync

# Doc inventory / generated docs
nix eval --json .#docInventory
python3 scripts/docs/generate.py --write

# Pre-commit checks（如该系统受支持）
nix build --no-link .#checks.aarch64-darwin.pre-commit
```
