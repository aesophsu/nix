# OpenClaw setup (Nix + Home Manager)

This repo uses [nix-openclaw](https://github.com/openclaw/nix-openclaw). Finish env and API keys below.

---

## Prerequisites

- **Determinate Nix** (<https://docs.determinate.systems/determinate-nix/>)
- **MacBook Air M4** (aarch64-darwin); config is tuned for this.

---

## 1. Nix and repo

```bash
nix --version
cd ~/Code/nix
```

---

## 2. Secrets dir (optional: Telegram)

```bash
mkdir -p ~/.secrets
chmod 700 ~/.secrets
```

**Current config has no Telegram.** Use **WebChat** or **CLI** (`openclaw agent --message "..."`).

To add Telegram later:

1. [@BotFather](https://t.me/BotFather) → token → `~/.secrets/openclaw-telegram-bot-token`
2. [@userinfobot](https://t.me/userinfobot) → your user ID
3. In `home/darwin/openclaw/default.nix` add:
   ```nix
   channels.telegram = {
     tokenFile = "${config.home.homeDirectory}/.secrets/openclaw-telegram-bot-token";
     allowFrom = [ YOUR_USER_ID ];
     groups."*" = { requireMention = true; };
   };
   ```

Optional gateway auth: `openssl rand -hex 32` → `OPENCLAW_GATEWAY_TOKEN` or `gateway.auth.token`.

---

## 3. OpenClaw config (optional edits)

1. **`home/darwin/openclaw/default.nix`**:
   - OpenAI as primary: set `openclawMinimalConfig.agents.defaults.model.primary` to `"openai/gpt-4o"` and `OPENAI_API_KEY`
   - Telegram: add `channels.telegram` (see step 2)

2. **`home/darwin/openclaw/documents/`**: Edit `AGENTS.md`, `SOUL.md`, `TOOLS.md`; extend from [OpenClaw templates](https://docs.openclaw.ai/reference/templates/) if needed.

---

## 4. Provider API key

At least one model provider. **Default: DeepSeek API.**

- **DeepSeek**: Set `DEEPSEEK_API_KEY` ([DeepSeek platform](https://platform.deepseek.com)). Models: `deepseek/deepseek-chat`, `deepseek/deepseek-reasoner`.
- Others: Add provider in config and set key.

Put key in `~/.secrets/openclaw-env`, source in shell (do not commit):

```bash
# ~/.secrets/openclaw-env (chmod 600)
export DEEPSEEK_API_KEY="sk-..."
```

(With agenix etc. you can read from secret file and export.)

---

## 5. Apply and verify

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

Open Gateway **WebChat** in browser or run `openclaw agent --message "hi"`.

---

## 6. Rollback and maintenance

- **Rollback**: `home-manager switch --rollback`
- **Restart gateway**: `launchctl kickstart -k gui/$(id -u)/com.steipete.openclaw.gateway`
- **After config/docs change**: `darwin-rebuild switch --flake .` or `home-manager switch --flake .#stella`

---

## OpenClaw-related paths in this repo

| Path | Role |
|------|------|
| `flake.nix` | Path inputs: nix-openclaw, flake-utils, nix-steipete-tools |
| `lib/openclaw-package.nix` | Build package (exclude oracle), PATH-safe wrapper (openclaw* bins only) |
| `outputs/default.nix` | genSpecialArgs → openclawPackageNoOracle for home |
| `modules/darwin/openclaw.nix` | Placeholder; overlay lives in stella.nix |
| `outputs/aarch64-darwin/src/stella.nix` | Injects nix-openclaw overlay and HM module |
| `home/darwin/openclaw/default.nix` | Enable, minimal config, instance, launchd, fallback activation |
| `home/darwin/openclaw/documents/` | AGENTS.md, SOUL.md, TOOLS.md |

Secrets stay in `~/.secrets/` and env; not in repo.
