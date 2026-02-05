# Mihomo

Proxy config (TUN, multi-upstream, AI rules). Tuned for MacBook Air M4.

## Deploy via Nix (recommended)

`home/darwin/mihomo/default.nix` links config to `~/.config/mihomo/config.yaml`. Precedence: `config.local.yaml` > `config.yaml` > `config.yaml.example` (this dir).

```bash
darwin-rebuild switch --flake .
# or HM only: home-manager switch --flake .#stella
```

Without Nix: copy `config.yaml` to `~/.config/mihomo/config.yaml` after editing.

## UI

Config uses `external-ui: ui`. Put a web panel in `~/.config/mihomo/ui/`, e.g. [yacd](https://github.com/haishan/yacd) or [mihomo-dashboard](https://github.com/MetaCubeX/mihomo-dashboard).

```bash
git clone https://github.com/haishan/yacd.git ~/.config/mihomo/ui
```

## Proxy

After apply: mihomo is default proxy. HTTP/HTTPS: 127.0.0.1:7890; SOCKS5: 127.0.0.1:7891. Env vars for CLI; networksetup for GUI. TUN enabled for full traffic (some apps may still need explicit proxy).

## Tuning in example

- bind-address: `*` → `127.0.0.1`
- inet4-route-exclude-address: `10.0.0.0/8`, `172.16.0.0/12` for LAN
- fake-ip-filter: Apple time sync hosts
- proxy-groups: YAML spacing fix
