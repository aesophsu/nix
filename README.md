# Nix 配置仓库（macOS / nix-darwin / Home Manager）

本仓库用于管理我的 macOS（当前主机 `stella`，MacBook Air M4）系统配置、用户环境与服务配置。

## 仓库架构图

```mermaid
flowchart TD
  F["`flake.nix`"] --> O["`outputs/`"]
  O --> ST["`outputs/aarch64-darwin/src/stella.nix`"]

  ST --> M["`modules/` (系统层, nix-darwin)"]
  ST --> H["`home/` (用户层, Home Manager)"]
  ST --> HOST["`hosts/darwin-stella/` (主机差异)"]
  ST --> V["`vars/` (共享变量)"]
  ST --> L["`lib/` (组装与辅助函数)"]

  M --> MB["`modules/base/` (跨平台基础模块)"]
  M --> MD["`modules/darwin/` (macOS 系统模块)"]
  MD --> MDM["`modules/darwin/maintenance/`"]
  MD --> MDP["`modules/darwin/profiles/`"]

  H --> HB["`home/base/` (跨平台用户配置)"]
  H --> HD["`home/darwin/` (macOS 用户配置)"]
  HD --> HDA["`home/darwin/apps/`"]
  HD --> HDS["`home/darwin/services/`"]
  HD --> HDP["`home/darwin/profiles/`"]

  HOST --> HOSTS["`default.nix` (系统层主机差异)"]
  HOST --> HOSTH["`home.nix` (用户层主机差异)"]
```

## 分层约定

| 层级 | 路径 | 说明 |
|---|---|---|
| 系统共享 | `modules/base/` | 跨平台系统模块（Nix、用户、安全、系统级包等） |
| 系统 macOS | `modules/darwin/` | `nix-darwin` 模块（Homebrew、macOS defaults、维护任务、存储 profile） |
| 用户共享 | `home/base/` | 跨平台 Home Manager 配置（CLI、语言栈、主题、shell 等） |
| 用户 macOS | `home/darwin/` | macOS 专用 Home Manager 配置（apps/services/profiles） |
| 主机差异 | `hosts/darwin-stella/` | 仅放 `stella` 独有配置，避免重复共享逻辑 |
| 共享变量 | `vars/` | 用户信息、网络、SSH 等共享变量 |
| 辅助函数 | `lib/` | `macosSystem`、路径与扫描工具等 |

## 文档入口

| 文档 | 说明 |
|---|---|
| `docs/README.md` | 文档总索引 |
| `DEPLOYMENT.md` | 部署流程（新机安装 / 重建） |
| `modules/README.md` | 系统模块结构说明 |
| `home/README.md` | Home Manager 结构说明 |
| `hosts/darwin-stella/README.md` | 主机差异边界说明 |

## 使用

```bash
darwin-rebuild switch --flake /Users/sue/Code/nix#stella
```

说明：本仓库大量使用 flake + Git 跟踪文件。新增目录或重命名文件后，请先 `git add`，否则 `.#stella` 评估可能看不到新文件。
