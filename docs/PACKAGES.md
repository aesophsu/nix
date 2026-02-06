# 软件管理说明

本仓库以 Nix 为系统配置与软件安装的单一事实来源。以下为各清单位置与约定。

## 系统级包

- **位置**：[modules/base/packages.nix](../modules/base/packages.nix)（及 modules/darwin 下各模块）
- **内容**：系统 CLI（git、openssl、mas、llvmPackages.openmp 等）；`environment.systemPackages`。

## 用户级包

- **位置**：[home/base/core/](../home/base/core/)（CLI/语言/工具）、[home/darwin/gui.nix](../home/darwin/gui.nix)（macOS GUI）
- **内容**：用户 CLI（eza、bat、fzf、uv、nodejs、go 等）、GUI 应用（如 google-chrome、zotero、code-cursor）、语言栈（Python 等）。

## Homebrew 例外

- **位置**：[modules/darwin/apps.nix](../modules/darwin/apps.nix)
- **约定**：仅保留当前无法用 Nix 安装的 cask（例如 ChatGPT 桌面）。CLI 与其余 GUI 均以 Nix 为准；`brews = [ ]`，casks 仅列必要项。

## Unfree 包

- 仅允许明确列出的 unfree 包，配置在 [modules/base/nixpkgs.nix](../modules/base/nixpkgs.nix) 的 `allowUnfreePredicate`。
- 新增 unfree 应用时，需在该列表中加入对应 `pname`（如 Cursor 在 nixpkgs 中为 `cursor`，另有 `google-chrome`、`zotero`）。

## 参考

- 部署流程：[DEPLOYMENT.md](../DEPLOYMENT.md)
