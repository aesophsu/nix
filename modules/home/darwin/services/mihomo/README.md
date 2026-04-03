# Mihomo（代理配置）

Mihomo 代理配置（TUN、多上游、AI 规则），面向 MacBook Air M4 场景调优。

## 通过 Nix 部署（推荐）

`modules/home/darwin/services/mihomo/default.nix` 会将配置链接到
`~/.config/mihomo/config.yaml`，并通过 launchd 保持 mihomo 常驻。优先级：`config.local.yaml` >
`config.yaml` > `config.yaml.example`（当前目录）。

```bash
darwin-rebuild switch --flake .
# or HM only: home-manager switch --flake .#stella
```

不使用 Nix 时：编辑后手动将 `config.yaml` 复制到 `~/.config/mihomo/config.yaml`。

## 订阅注意事项

- `config.local.yaml` 用于保存真实订阅地址与 token；不要提交到仓库。
- `config.local.yaml` 也用于保存本机 `external-controller` 的 `secret`；模板里只放占位符。
- 如果机场提供的是一次性订阅链接，不要先用浏览器、`curl` 或其它探测工具访问；否则链接可能会被提前消费并失效。
- 一次性订阅链接的推荐流程：先写入 `config.local.yaml`，再执行 `darwin-rebuild switch --flake .`，随后重启 `mihomo`，只让 `mihomo` 自己完成那一次拉取。
- 如果一次性订阅链接已经被消费，直接去机场官网重置，不要继续在本机反复重试。
- 当前配置中 `Airport2` 的 provider 下载通过隐藏的 `Airport1Bootstrap` 组完成引导，目的是避免 `Airport2` 订阅更新完全依赖不稳定的直连链路。

## Web UI

Config uses `external-ui: ui`. Put a web panel in `~/.config/mihomo/ui/`, e.g.
[yacd](https://github.com/haishan/yacd) or
[mihomo-dashboard](https://github.com/MetaCubeX/mihomo-dashboard).

```bash
git clone https://github.com/haishan/yacd.git ~/.config/mihomo/ui
```

## 代理端口与行为

应用后，mihomo 会常驻运行，但不会自动接管流量：

- HTTP/HTTPS：`127.0.0.1:7890`
- SOCKS5：`127.0.0.1:7891`
- REST API：`127.0.0.1:9090`（仅本机，需 `secret`）
- 系统代理手动切换：`proxy-on` / `proxy-off`
- 当前 shell 手动导出：`eval "$(proxy-env-on)"` / `eval "$(proxy-env-off)"`
- 已启用 TUN（个别应用仍可能需要显式代理）

## 最小暴露面默认值

- `allow-lan: false`
- `bind-address: 127.0.0.1`
- `external-controller: 127.0.0.1:9090`
- 为 `external-controller` 设置强随机 `secret`
- DNS 不同时启用 `prefer-h3` 和 `respect-rules`
