# Home Manager's Submodules

This directory contains all Home Manager configurations organized by platform and functionality.

## Current Structure

```
home/
├── base/              # 跨平台配置
│   ├── core/          # 核心应用（git、neovim、python、starship、theme、shells）
│   └── home.nix       # home.stateVersion、username 等入口
└── darwin/            # macOS 专用
    ├── default.nix    # 入口，scanPaths 加载子模块
    ├── shell.nix      # 开发 shell
    ├── mihomo/        # 代理（default.nix + config 文件）
    ├── openclaw/      # OpenClaw（default.nix + documents）
    └── postgresql/    # PostgreSQL 16（default.nix）
```

## Module Overview

1. **base**：跨平台，被 darwin 的 `default.nix` 引入（`../base/core`、`../base/home.nix`）。
2. **darwin**：macOS 专用；入口为 `default.nix`，通过 `mylib.scanPaths` 加载本目录下所有 `.nix` 与子目录；子模块为 mihomo、openclaw、postgresql。对应用户由 `vars/default.nix` 的 `username` 指定（当前为 sue），主机配置名为 stella（`--flake .#stella`）。
