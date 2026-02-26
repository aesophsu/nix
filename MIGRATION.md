# 迁移说明（第二阶段：单机极简重构）

记录将仓库从“多主机/多平台框架”收敛为“仅 `stella` 的 Darwin 配置”后的主要路径与装配方式变更，便于排错、搜索与脚本更新。

## 核心变化

- 移除 host registry 抽象：不再使用 `hosts/registry.nix` 与 `lib/host-registry.nix`
- 移除 platform fragments 抽象：`outputs/darwin/` 直接构建 `darwinConfigurations.stella`
- 目录重命名：`modules/` -> `system/`，`home/` -> `user/`
- 主机目录重命名：`hosts/darwin-stella/` -> `hosts/stella/`

## 路径映射（旧 -> 新）

| 旧路径 | 新路径 |
|---|---|
| `modules/base/` | `system/common/` |
| `modules/darwin/` | `system/darwin/` |
| `home/base/` | `user/common/` |
| `home/darwin/` | `user/darwin/` |
| `hosts/darwin-stella/` | `hosts/stella/` |
| `hosts/darwin-stella/default.nix` | `hosts/stella/system.nix` |
| `outputs/aarch64-darwin/` | `outputs/darwin/` |

## 删除的抽象与文件

- `hosts/registry.nix`
- `lib/host-registry.nix`
- `outputs/lib/host-registry.nix`
- `outputs/lib/mk-platform-outputs.nix`
- `outputs/lib/platform-output.nix`
- `outputs/darwin/fragments/`

## 输出装配层变化

- `outputs/default.nix` 直接维护单机 `stella` 的 `docInventory` 元信息
- `outputs/darwin/default.nix` 直接组合：
  - `system/common`
  - `system/darwin`
  - `hosts/stella/system.nix`
  - `hosts/stella/home.nix`
  - `user/darwin`
- `outputs/darwin/tests/default.nix` 改为固定的 `stella` smoke tests（不再按 host 遍历）

## 注意事项

- 使用 flake 时，新增目录或重命名文件后请先 `git add`，否则 `.#stella` 评估可能看不到新文件。
- 本说明聚焦结构迁移；实际功能行为以当前 `system/`、`user/`、`hosts/stella/` 与 `outputs/` 中实现为准。
