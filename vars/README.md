# Variables

Common variables and configuration used across my NixOS and nix-darwin configurations.

## Current Structure

```
vars/
├── README.md
├── default.nix         # Main variables entry point
└── networking.nix      # Network configuration and host definitions
```

## Components

### 1. `default.nix`

Contains user information, SSH keys, and password configuration:

- User credentials (username, full name, email)
- Initial hashed password for new installations
- SSH authorized keys (main and backup sets)
- Public key references for system access

### 2. `networking.nix`

网络与主机相关配置（面向中国大陆优化）：

- **mihomo**：代理端口与 URL（与 `home/darwin/mihomo/config.yaml` 或 `config.local.yaml` 一致）；mihomo 由 Nix 部署（home/darwin/mihomo），launchd 自动启动，无需单独安装
- **nameservers**：国内 DNS（DNSPod、AliDNS），可选备选 114/百度
- **hostsAddr / hostsInterface**：主机网络接口与 DHCP 配置（当前仅 stella）
- **ssh**：`knownHosts`（如 GitHub）等，供 nix-darwin 使用

**国内镜像一览**（在各自模块中配置）：Nix 使用清华/中科大 store 镜像（`modules/base/nix.nix`）；Homebrew 使用北外 bottles 与 git 镜像（`modules/darwin/apps.nix`）；PyPI 使用清华/南大（`home/base/core/pip.nix`、mihomo no_proxy）。

## Usage

These variables are imported and used throughout the configuration to ensure consistency across all
hosts and maintain centralized network and security settings.
