# 迁移说明（目录重构）

记录本次 Nix 配置目录重构后的主要路径迁移，便于排错、搜索与脚本更新。

## 适用范围

- `home/darwin/` 按 `apps/`、`services/`、`profiles/` 分组
- `modules/darwin/` 按 `maintenance/`、`profiles/` 分组
- `home/base/core/core.nix` 更名为 `packages.nix`
- `modules/base/packages.nix` 更名为 `system-packages.nix`

## 路径映射（旧 -> 新）

### Home Manager（Darwin）

| 旧路径 | 新路径 |
|---|---|
| `home/darwin/gui.nix` | `home/darwin/apps/gui.nix` |
| `home/darwin/shell.nix` | `home/darwin/profiles/shell.nix` |
| `home/darwin/mihomo/default.nix` | `home/darwin/services/mihomo/default.nix` |
| `home/darwin/mihomo/config.yaml.example` | `home/darwin/services/mihomo/config.yaml.example` |
| `home/darwin/postgresql/default.nix` | `home/darwin/services/postgresql/default.nix` |

### Home Manager（Base）

| 旧路径 | 新路径 |
|---|---|
| `home/base/core/core.nix` | `home/base/core/packages.nix` |

### nix-darwin 模块

| 旧路径 | 新路径 |
|---|---|
| `modules/darwin/nix-core.nix` | `modules/darwin/nix-determinate.nix` |
| `modules/darwin/nix-maintenance.nix` | `modules/darwin/maintenance/nix-store.nix` |
| `modules/darwin/zz-256g-aggressive.nix` | `modules/darwin/profiles/storage-256g-aggressive.nix` |

### 基础系统模块（Base）

| 旧路径 | 新路径 |
|---|---|
| `modules/base/packages.nix` | `modules/base/system-packages.nix` |

## 文档变更

- 新增仓库总览与架构图：`README.md`
- 新增生成文档目录：`docs/generated/`（由 `scripts/docs/generate.py` 维护）
- 删除重复 README：`home/base/README.md`、`modules/darwin/README.md`
- 文档风格统一为中文主叙述，路径统一使用反引号

## 输出装配层变更（新）

- `outputs/*/src/hosts.nix` 更名为 `outputs/*/fragments/hosts.nix`
- `outputs/lib/mk-platform-outputs.nix` 统一平台输出装配模板（替代 `haumea` loader）

## 注意事项

- 使用 flake 时，新增目录或重命名文件后请先 `git add`，否则 `.#stella` 评估可能看不到新文件。
- 本说明主要覆盖“路径迁移”；功能行为以各模块当前实现为准。
