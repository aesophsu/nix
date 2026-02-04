# Home Manager · Base（跨平台）

跨平台 Home Manager 配置，被 Linux 与 Darwin 共用。

## 结构

| 路径 | 说明 |
|------|------|
| **home.nix** | 入口：`home.username`、`home.stateVersion` 等基础项 |
| **core/** | 核心应用与设置，由 `core/default.nix` 扫描并导入 |
| **core/default.nix** | 通过 `mylib.scanPaths ./.** 导入本目录下所有 `.nix` 与子目录 |
| **core/core.nix** | 基础 home 选项 |
| **core/git.nix** | Git 配置与别名 |
| **core/neovim.nix** | Neovim 配置 |
| **core/pip.nix** | Python pip 相关 |
| **core/python.nix** | Python 与虚拟环境 |
| **core/starship.nix** | 跨 shell 提示符（Starship） |
| **core/theme.nix** | 主题与配色 |
| **core/shells/** | Shell 配置（如 Nushell `config.nu`） |

## 加载方式

- `home/darwin/default.nix` 会 `import ../base/core` 与 `import ../base/home.nix`，因此所有 Darwin 用户都会带上 base 配置。
