# OpenClaw checklist

Done + your follow-ups.

---

## Done

- [x] **1** Determinate Nix installed (`nix (Determinate Nix 3.15.2)`)
- [x] **2** `~/.secrets` (700) with `openclaw-telegram-bot-token.placeholder`, `openclaw-env.example`
- [x] **3** No Telegram; WebChat/CLI only. Add `channels.telegram` in config when needed.
- [x] **4** Copy `openclaw-env.example` → fill API key → source.

---

## Your steps

### 1. (Optional) Telegram later

In `home/darwin/openclaw/default.nix` add `channels.telegram` (tokenFile, allowFrom) and create `~/.secrets/openclaw-telegram-bot-token`.

### 2. Model API key

```bash
cp ~/.secrets/openclaw-env.example ~/.secrets/openclaw-env
# Edit: export DEEPSEEK_API_KEY="sk-..."
chmod 600 ~/.secrets/openclaw-env
```

In `~/.zshrc`:

```bash
[ -f ~/.secrets/openclaw-env ] && source ~/.secrets/openclaw-env
```

Then `source ~/.zshrc`.

### 3. Apply config

Path inputs (see `flake.nix`); clone with proxy if needed. Then:

```bash
cd ~/Code/nix
sudo darwin-rebuild switch --flake .
```

Or Home Manager only: `home-manager switch --flake .#stella`

### 4. Verify

```bash
launchctl print gui/$(id -u)/com.steipete.openclaw.gateway | grep state
tail -50 /tmp/openclaw/openclaw-gateway.log
```

Open WebChat or run `openclaw agent --message "hi"`.

---

## Commands

| Action | Command |
|--------|---------|
| Rollback | `home-manager switch --rollback` |
| Restart gateway | `launchctl kickstart -k gui/$(id -u)/com.steipete.openclaw.gateway` |

GitHub may need proxy (e.g. start mihomo before `darwin-rebuild switch`).
