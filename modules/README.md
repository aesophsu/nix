# NixOS / Nix-Darwin's Submodules

This directory contains modular NixOS and Nix-Darwin configurations organized by platform and
functionality.

## Current Structure

```
modules/
├── README.md
├── base/                    # Common configuration for all platforms
│   ├── default.nix
│   ├── fonts.nix           # System font configuration
│   ├── nix.nix            # Nix package manager settings
│   ├── overlays.nix       # Package overlays
│   ├── security.nix       # Basic security settings
│   ├── packages.nix       # Essential system packages
│   └── users.nix          # User management
└── darwin/                  # macOS-specific modules
    ├── README.md
    ├── apps.nix            # Homebrew、环境变量、GUI 应用
    ├── broken-packages.nix # 包兼容修复
    ├── default.nix
    ├── nix-core.nix        # Nix 核心设置
    ├── openclaw.nix        # nix-openclaw overlay
    ├── security.nix        # macOS 安全设置
    ├── ssh.nix             # SSH 配置
    ├── system.nix         # 系统级设置（代理、时区、defaults）
    └── users.nix          # 用户与 SSH 公钥
```

## Module Categories

### 1. **Base Modules** (`base/`)

Common configuration shared between NixOS and macOS:

- System fonts and localization
- Essential packages and tools
- Basic security settings
- User management
- Package overlays

### 2. **macOS Modules** (`darwin/`)

macOS-specific configuration:

- macOS applications and system settings
- Security configurations tailored for macOS
- SSH and system-level settings
- Package compatibility fixes

## Usage

- **macOS**：`outputs/aarch64-darwin/src/stella.nix` 引入 `modules/darwin` 与 `hosts/darwin-stella`，并合并 `base/` 共享配置。
- **所有系统**：`base/` 被 darwin 的 `default.nix` 引入，提供字体、Nix 设置、overlays、包、安全与用户等通用配置。

## 当前架构

- **aarch64-darwin**：MacBook Air M4（hostname: stella）
