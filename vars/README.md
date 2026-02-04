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

网络与主机相关配置：

- **mihomo**：代理端口与 URL（与 `home/darwin/mihomo/config.yaml` 或 `config.local.yaml` 一致）
- **nameservers**：国内 DNS（DNSPod、AliDNS）
- **hostsAddr / hostsInterface**：主机网络接口与 DHCP 配置（当前仅 stella）
- **ssh**：`knownHosts`（如 GitHub）等，供 nix-darwin 使用

## Usage

These variables are imported and used throughout the configuration to ensure consistency across all
hosts and maintain centralized network and security settings.
