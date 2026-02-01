# Mihomo 配置

MacBook Air M4 优化配置，支持 TUN 模式、多机场、AI 分流等。

## 部署方式

### 方式一：通过 Nix（推荐）

```bash
darwin-rebuild switch --flake .#stella
# 或
home-manager switch --flake .#stella
```

### 方式二：手动复制

```bash
cp home/darwin/mihomo/config.yaml ~/.config/mihomo/config.yaml
```

## 外部 UI

配置使用 `external-ui: ui`，需在 `~/.config/mihomo/ui/` 放置 Web 面板，例如：

- [yacd](https://github.com/haishan/yacd) - 轻量
- [mihomo-dashboard](https://github.com/MetaCubeX/mihomo-dashboard) - 官方

```bash
# 示例：使用 yacd
git clone https://github.com/haishan/yacd.git ~/.config/mihomo/ui
```

## 代理设置

应用配置后，mihomo 会自动作为本机默认代理：

| 类型 | 地址 | 用途 |
|------|------|------|
| HTTP/HTTPS | 127.0.0.1:7890 | 环境变量 + macOS 系统代理 |
| SOCKS5 | 127.0.0.1:7891 | 环境变量 + macOS 系统代理 |

- **环境变量**：`http_proxy`、`https_proxy`、`all_proxy` 等，供 curl、wget、git 等 CLI 工具使用
- **macOS 系统代理**：通过 `networksetup` 设置，供 Safari、Chrome 等 GUI 应用使用
- **TUN 模式**：已启用，可接管全机流量（部分应用可能仍需显式代理）

## 本次优化说明

1. **bind-address**: `*` → `127.0.0.1`，公共网络下仅监听本机更安全
2. **inet4-route-exclude-address**: 取消注释并补充 `10.0.0.0/8`、`172.16.0.0/12`，便于访问家庭/办公室内网
3. **fake-ip-filter**: 增加 `time-ios.apple.com`、`ntp.apple.com`，改善 Apple 设备时间同步
4. **proxy-groups**: 修正 YAML 格式（`name:` 与 `{` 之间加空格）
