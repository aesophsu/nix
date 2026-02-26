# 软件管理说明

本仓库以 Nix 为系统配置与软件安装的单一事实来源。以下为各清单位置与约定。

## 系统级包

- **位置**：[system/common/system-packages.nix](../system/common/system-packages.nix)（及 system/darwin 下各模块）
- **内容**：系统 CLI（git、openssl、mas、llvmPackages.openmp 等）；`environment.systemPackages`。

## 用户级包

- **位置**：[user/common/core/](../user/common/core/)（CLI/语言/工具）、[user/darwin/apps/gui.nix](../user/darwin/apps/gui.nix)（macOS GUI 层）
- **内容**：用户 CLI（eza、bat、fzf、uv、nodejs、go 等）、语言栈（Python 等）、以及少量仍由 Nix 管理的 GUI（若有）。

## Homebrew 例外

- **位置**：[system/darwin/apps.nix](../system/darwin/apps.nix)（基础 Homebrew 策略）、[system/darwin/profiles/storage-256g-aggressive.nix](../system/darwin/profiles/storage-256g-aggressive.nix)（256G 激进存储 profile）
- **约定**：在 256G profile 下，重量级 GUI（如 `codex-app`、Chrome、Telegram、Zotero、Cursor）优先走 Homebrew cask，减少 Nix store 代际占用；`brews = [ ]`，casks 仅列必要项。

## Unfree 包

- 仅允许明确列出的 unfree 包，配置在 [system/common/nixpkgs.nix](../system/common/nixpkgs.nix) 的 `allowUnfreePredicate`。
- 新增 unfree 应用时，需在该列表中加入对应 `pname`（如 Cursor 在 nixpkgs 中为 `cursor`，另有 `google-chrome`、`zotero`）。

## 参考

- 部署流程：[DEPLOYMENT.md](../DEPLOYMENT.md)
