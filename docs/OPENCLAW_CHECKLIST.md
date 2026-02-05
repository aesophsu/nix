# OpenClaw 设置清单（你需补做的项）

以下为本次已做 + 你需要补做/重试的步骤。

---

## 已完成的设置

- [x] **步骤 1**：已确认 Determinate Nix 已安装（`nix (Determinate Nix 3.15.2)`）
- [x] **步骤 2**：已创建 `~/.secrets`（700），并添加：
  - `~/.secrets/openclaw-telegram-bot-token.placeholder`（说明如何创建 token 文件）
  - `~/.secrets/openclaw-env.example`（API 密钥模板）
- [x] **步骤 3**：已改为**不配置 Telegram**，使用 WebChat/CLI 即可；需要时再在配置中加 `channels.telegram`
- [x] **步骤 4**：已提供 `openclaw-env.example`，你需要复制并填入 API Key 并 source

---

## 你需要补做的项

### 1. （可选）以后要接 Telegram 时

在 `home/darwin/openclaw/default.nix` 的 `config` 中增加 `channels.telegram`（tokenFile、allowFrom），并创建 `~/.secrets/openclaw-telegram-bot-token`。当前无需 Telegram 即可使用 WebChat/CLI。

### 2. 设置模型 API 密钥

```bash
cp ~/.secrets/openclaw-env.example ~/.secrets/openclaw-env
# 编辑 ~/.secrets/openclaw-env，填入 DeepSeek 官方 API Key（当前配置为直连）
#   export DEEPSEEK_API_KEY="sk-..."
chmod 600 ~/.secrets/openclaw-env
```

在 `~/.zshrc` 里加上（以便终端和本机服务能用到）：

```bash
[ -f ~/.secrets/openclaw-env ] && source ~/.secrets/openclaw-env
```

然后执行一次：`source ~/.zshrc`。

### 3. 应用配置

本仓库使用 **path 输入**（`nix-openclaw`、`flake-utils`、`nix-steipete-tools`）避免 Nix daemon 从 GitHub 直连。首次需在「已开代理」的终端克隆上述仓库到本地（见 `flake.nix` 注释）。之后执行：

```bash
cd /Users/sue/nix
sudo darwin-rebuild switch --flake .
```

或仅 Home Manager：

```bash
home-manager switch --flake .#stella
```

### 4. 验证与测试

```bash
# 查看 launchd 状态
launchctl print gui/$(id -u)/com.steipete.openclaw.gateway | grep state

# 查看最近日志
tail -50 /tmp/openclaw/openclaw-gateway.log
```

用浏览器打开 Gateway 的 WebChat，或运行 `openclaw agent --message "你好"` 测试。

---

## 日常命令

| 操作     | 命令 |
|----------|------|
| 回滚     | `home-manager switch --rollback` |
| 重启网关 | `launchctl kickstart -k gui/$(id -u)/com.steipete.openclaw.gateway` |

---

**说明**：若在中国大陆，GitHub 可能需代理。可先开启 mihomo 等代理后再执行 `darwin-rebuild switch`。
