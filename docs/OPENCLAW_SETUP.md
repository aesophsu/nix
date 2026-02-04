# OpenClaw 安装与配置步骤（Nix + Home Manager）

本仓库已集成 [nix-openclaw](https://github.com/openclaw/nix-openclaw)，按以下步骤完成环境与密钥配置即可使用。

---

## 前置要求

- **Determinate Nix** 已安装（若未安装：<https://docs.determinate.systems/determinate-nix/>）
- 本机为 **MacBook Air M4**（aarch64-darwin），当前配置已按此优化

---

## 步骤一：确认 Nix 与仓库

```bash
# 确认 Nix 可用
nix --version

# 进入本配置仓库（路径按你克隆位置调整，如 ~/nix）
cd /Users/sue/nix
```

---

## 步骤二：准备 Secrets 目录（可选：Telegram）

```bash
mkdir -p ~/.secrets
chmod 700 ~/.secrets
```

**当前配置不包含 Telegram**，可直接用本地 **WebChat** 或 **CLI**（`openclaw agent --message "..."`）与助手对话。

若以后要接 Telegram：

1. [@BotFather](https://t.me/BotFather) 创建 Bot，获得 Token，写入 `~/.secrets/openclaw-telegram-bot-token`
2. [@userinfobot](https://t.me/userinfobot) 获取你的用户 ID
3. 在 `home/darwin/openclaw/default.nix` 的 `config` 中增加：
   ```nix
   channels.telegram = {
     tokenFile = "${config.home.homeDirectory}/.secrets/openclaw-telegram-bot-token";
     allowFrom = [ 你的用户ID ];
     groups."*" = { requireMention = true; };
   };
   ```

（可选）网关认证：`openssl rand -hex 32` 得到串，设环境变量 `OPENCLAW_GATEWAY_TOKEN` 或在配置中填 `gateway.auth.token`。

---

## 步骤三：按需修改 OpenClaw 配置

1. 编辑 **`home/darwin/openclaw/default.nix`**（可选）：
   - 若要用 **OpenAI** 作为主模型：修改 `openclawMinimalConfig.agents.defaults.model.primary` 为 `"openai/gpt-4o"`，并设置 `OPENAI_API_KEY`
   - 若以后要启用 Telegram：在 `config` 中加上 `channels.telegram`（见步骤二）

2. （可选）编辑 **`home/darwin/openclaw/documents/`** 下的 `AGENTS.md`、`SOUL.md`、`TOOLS.md`，按需从 [OpenClaw 模板](https://docs.openclaw.ai/reference/templates/) 扩展。

---

## 步骤四：Provider API 密钥（模型）

OpenClaw 需要至少一个模型 Provider：

- **Anthropic（Claude）**：设置环境变量 `ANTHROPIC_API_KEY`，或在 nix-openclaw 支持的 config 中配置。
- **OpenAI（GPT）**：设置环境变量 `OPENAI_API_KEY`，并将 `agent.model` 改为 `openai/gpt-4o`（见步骤三）。

可将密钥放在 `~/.secrets` 并在 shell 或 launchd 中 source，例如：

```bash
# 示例：~/.zshrc 或 launchd 环境
export ANTHROPIC_API_KEY="sk-ant-..."
# 或
export OPENAI_API_KEY="sk-..."
```

（若使用 agenix 等，可改为从 secret 文件读取后 export。）

---

## 步骤五：应用配置并验证

```bash
# 在仓库根目录执行
darwin-rebuild switch --flake .

# 或仅 Home Manager
home-manager switch --flake .#stella
```

验证服务与日志：

```bash
# 查看 launchd 状态
launchctl print gui/$(id -u)/com.steipete.openclaw.gateway | grep state

# 查看最近日志
tail -50 /tmp/openclaw/openclaw-gateway.log
```

未配置 Telegram 时，在浏览器打开 Gateway 提供的 **WebChat**，或在本机运行 `openclaw agent --message "你好"` 与助手对话。

---

## 步骤六：回滚与日常维护

- **回滚**：`home-manager switch --rollback`
- **重启 Gateway**：`launchctl kickstart -k gui/$(id -u)/com.steipete.openclaw.gateway`
- **更新配置**：改完 `home/darwin/openclaw/default.nix` 或 documents 后再次执行 `darwin-rebuild switch --flake .` 或 `home-manager switch --flake .#stella`

---

## 本仓库中与 OpenClaw 相关的文件（位置与职责）

| 路径 | 说明 |
|------|------|
| `flake.nix` | `nix-openclaw`、`flake-utils`、`nix-steipete-tools` 等 path 输入 |
| `lib/openclaw-package.nix` | 构建排除 oracle 的包，并做 PATH 安全包装（仅暴露 openclaw* bin） |
| `outputs/default.nix` | `genSpecialArgs` 调用 lib 产出 `openclawPackageNoOracle`，供 home 使用 |
| `modules/darwin/openclaw.nix` | 为系统提供 nix-openclaw overlay |
| `outputs/aarch64-darwin/src/stella.nix` | 引入 nix-openclaw Home Manager 模块 |
| `home/darwin/openclaw/default.nix` | OpenClaw 启用、最小 config、实例与 launchd、fallback activation |
| `home/darwin/openclaw/documents/` | AGENTS.md、SOUL.md、TOOLS.md 占位 |

Secrets 仅放在 `~/.secrets/` 与环境中，不进入仓库。
