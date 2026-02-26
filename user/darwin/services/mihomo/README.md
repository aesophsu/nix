# Mihomo（代理配置）

Mihomo 代理配置（TUN、多上游、AI 规则），面向 MacBook Air M4 场景调优。

## 通过 Nix 部署（推荐）

`user/darwin/services/mihomo/default.nix` 会将配置链接到 `~/.config/mihomo/config.yaml`。
优先级：`config.local.yaml` > `config.yaml` > `config.yaml.example`（当前目录）。

```bash
darwin-rebuild switch --flake .
# or HM only: home-manager switch --flake .#stella
```

不使用 Nix 时：编辑后手动将 `config.yaml` 复制到 `~/.config/mihomo/config.yaml`。

## Web UI

Config uses `external-ui: ui`. Put a web panel in `~/.config/mihomo/ui/`, e.g. [yacd](https://github.com/haishan/yacd) or [mihomo-dashboard](https://github.com/MetaCubeX/mihomo-dashboard).

```bash
git clone https://github.com/haishan/yacd.git ~/.config/mihomo/ui
```

## 代理端口与行为

应用后，mihomo 会成为默认代理：

- HTTP/HTTPS：`127.0.0.1:7890`
- SOCKS5：`127.0.0.1:7891`
- CLI 走环境变量；GUI 通过 `networksetup`
- 已启用 TUN（个别应用仍可能需要显式代理）

## 示例配置中的调优项

- bind-address: `*` → `127.0.0.1`
- inet4-route-exclude-address: `10.0.0.0/8`, `172.16.0.0/12` for LAN
- fake-ip-filter: Apple time sync hosts
- proxy-groups: YAML spacing fix
