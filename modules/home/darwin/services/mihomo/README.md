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
- `Airport1` 已停用。上游机场已禁止第三方代理客户端，并要求只能使用其官方客户端，因此当前受管配置不再引用 `Airport1`。
- `Airport2` 是当前唯一保留的上游，并继续作为常规 `http provider` 自动更新。
- 旧的 `airport1.yaml` / `airport1-controlled.yaml` 可以留作历史快照排障，但不再参与 `mihomo` 分组与选路。

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
