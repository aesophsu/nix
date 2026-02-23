# OpenClaw 配置说明（Nix + Home Manager）

本仓库通过 [nix-openclaw](https://github.com/openclaw/nix-openclaw) 接入 OpenClaw。以下步骤用于补齐环境与 API Key。

## 前提条件

- **Determinate Nix** (<https://docs.determinate.systems/determinate-nix/>)
- **MacBook Air M4** (aarch64-darwin); config is tuned for this.

## 1. 检查 Nix 与仓库路径

```bash
nix --version
cd ~/Code/nix
```

## 2. 准备 secrets 目录（可选：Telegram）

```bash
mkdir -p ~/.secrets
chmod 700 ~/.secrets
```

当前配置默认**不启用 Telegram**。可直接使用 **WebChat** 或 CLI（`openclaw agent --message "..."`）。

To add Telegram later:

1. [@BotFather](https://t.me/BotFather) → token → `~/.secrets/openclaw-telegram-bot-token`
2. [@userinfobot](https://t.me/userinfobot) → your user ID
3. In `home/darwin/services/openclaw/default.nix` add:
   ```nix
   channels.telegram = {
     tokenFile = "${config.home.homeDirectory}/.secrets/openclaw-telegram-bot-token";
     allowFrom = [ YOUR_USER_ID ];
     groups."*" = { requireMention = true; };
   };
   ```

可选 gateway 鉴权：`openssl rand -hex 32`，再设置 `OPENCLAW_GATEWAY_TOKEN` 或 `gateway.auth.token`。

## 3. OpenClaw 配置（可选修改）

1. **`home/darwin/services/openclaw/default.nix`**:
   - OpenAI as primary: set `openclawMinimalConfig.agents.defaults.model.primary` to `"openai/gpt-4o"` and `OPENAI_API_KEY`
   - Telegram: add `channels.telegram` (see step 2)

2. **`home/darwin/services/openclaw/documents/`**: Edit `AGENTS.md`, `SOUL.md`, `TOOLS.md`; extend from [OpenClaw templates](https://docs.openclaw.ai/reference/templates/) if needed.

## 4. Provider API Key

至少需要一个模型 provider。默认使用 **DeepSeek API**。

- **DeepSeek**: Set `DEEPSEEK_API_KEY` ([DeepSeek platform](https://platform.deepseek.com)). Models: `deepseek/deepseek-chat`, `deepseek/deepseek-reasoner`.
- Others: Add provider in config and set key.

建议将密钥放到 `~/.secrets/openclaw-env`，由 shell 加载（不要提交到仓库）：

```bash
# ~/.secrets/openclaw-env (chmod 600)
export DEEPSEEK_API_KEY="sk-..."
```

（如使用 agenix 等方案，也可以从 secrets 文件读取后导出。）

## 5. 应用并验证

```bash
darwin-rebuild switch --flake .
# Or Home Manager only:
home-manager switch --flake .#stella
```

Check service and logs:

```bash
launchctl print gui/$(id -u)/com.steipete.openclaw.gateway | grep state
tail -50 /tmp/openclaw/openclaw-gateway.log
```

在浏览器中打开 Gateway **WebChat**，或执行 `openclaw agent --message "hi"`。

## 6. 回滚与维护

- **Rollback**: `home-manager switch --rollback`
- **Restart gateway**: `launchctl kickstart -k gui/$(id -u)/com.steipete.openclaw.gateway`
- **After config/docs change**: `darwin-rebuild switch --flake .` or `home-manager switch --flake .#stella`

## 仓库内 OpenClaw 相关路径

| 路径 | 说明 |
|---|---|
| `flake.nix` | Path inputs：`nix-openclaw`、`flake-utils`、`nix-steipete-tools` |
| `lib/openclaw-package.nix` | 构建包（排除 oracle）与 PATH-safe wrapper（仅 `openclaw*`） |
| `outputs/default.nix` | `genSpecialArgs` 向 Home 层注入 `openclawPackageNoOracle` |
| `outputs/aarch64-darwin/src/stella.nix` | 注入 `nix-openclaw` overlay 与 HM module |
| `home/darwin/services/openclaw/default.nix` | 启用、最小配置、实例、launchd、fallback activation |
| `home/darwin/services/openclaw/documents/` | `AGENTS.md`、`SOUL.md`、`TOOLS.md` |

说明：本仓库没有单独的 `modules/darwin/openclaw.nix`；overlay 与 HM module 在 `stella` 入口接线。
Secrets 保持在 `~/.secrets/` 与环境变量中，不进入仓库。
