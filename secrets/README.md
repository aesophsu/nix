# Secrets (`secrets/`) via agenix (dual-mode)

本目录提供公开仓库内的 secrets 接口层，不存放明文 secrets。

## 模式（自动检测）

`secrets/source.nix` 按以下优先级解析密文来源：

1. `inputs.mysecrets`（私有仓库，`flake = false`，推荐）
2. `secrets/local/`（本地 fallback，gitignored）
3. disabled（未配置 secrets，模块回退到现有非 agenix 路径）

## 文件说明

- `source.nix`：密文来源解析（private/local/disabled）
- `schema.nix`：secret 名称到相对密文路径映射（不含明文）
- `nixos.nix`：NixOS agenix 模块（系统级解密）
- `home-manager.nix`：Home Manager agenix 模块（用户级解密，Darwin 可用）
- `local/`：本地 fallback 密文目录（gitignored）

## 私有仓库模式（推荐）

在你自己的本地分支或私有 fork 中启用 `flake.nix` 的 `mysecrets` input（`flake = false`），
然后将 `.age` 密文放在私有仓库中，路径结构与 `schema.nix` 一致。

## 本地 fallback 模式

在 `secrets/local/` 下放置 `.age` 密文（同样遵循 `schema.nix` 的目录结构），适合单机测试。

## 审计

配套审计脚本：`scripts/security/audit-secrets.sh`（仅扫描 tracked 内容）。
