# Fresh macOS deploy guide

MacBook Air M4 (aarch64-darwin), Determinate Nix + nix-darwin + Home Manager.

## Mainland / proxy notes

- **First deploy without proxy**: Nix uses substituter mirrors, Homebrew uses BFSU mirror. One `darwin-rebuild switch` deploys mihomo (package + launchd + config link); no separate install.
- **mihomo via Nix**: Package, env vars, `~/.config/mihomo/config.yaml` link, launchd are in `home/darwin/mihomo/default.nix`. Prepare config in repo (step 3); launchd starts mihomo on login.
- **Path inputs**: OpenClaw deps are path inputs (no GitHub at eval). Clone them once (with proxy if needed), then deploy.
- **brew/mas errors**: Comment out `masApps` or some taps to finish first deploy; add mihomo config, then run the same `darwin-rebuild switch` again.
- **GitHub access** (e.g. `nix flake update`): Use mihomo sessionVariables in shell, or set `http-proxy` / `https-proxy` in `~/.config/nix/nix.conf`.

## Prerequisites

- Fresh macOS, user `sue` (match `vars/default.nix` `username`).

---

## 0. SSH key (before clone)

Generate key and add to GitHub so `git clone git@github.com:...` works.

```bash
# 1. Generate key
ssh-keygen -t ed25519 -C "aesophsu@gmail.com"

# 2. Start ssh-agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 3. Copy public key (macOS)
pbcopy < ~/.ssh/id_ed25519.pub
```

Add key at [GitHub → Settings → SSH and GPG keys](https://github.com/settings/keys).

```bash
# 4. Test (accept github.com fingerprint when prompted)
ssh -T git@github.com
```

---

## 1. Install Nix (Determinate)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Restart terminal or `source /etc/nix/profile/nix.sh`.

---

## 2. Clone config repo

```bash
mkdir -p ~/Code
cd ~/Code
git clone git@github.com:aesophsu/nix.git nix
cd nix
```

---

## 3. Mihomo config (Nix deploys the rest)

Nix (Home Manager) deploys mihomo in step 5. Prepare config in repo (subscription URL/token; do not commit secrets):

```bash
cp home/darwin/mihomo/config.yaml.example home/darwin/mihomo/config.yaml
# Edit and add subscription URL, or use config.local.yaml (higher priority, often .gitignored)
```

After step 5, launchd starts mihomo automatically.

---

## 4. (Optional) OpenClaw path inputs

OpenClaw uses path inputs so the daemon doesn’t hit GitHub. Clone with proxy if needed (see `flake.nix`):

```bash
mkdir -p ~/Code/claw
git clone https://github.com/numtide/flake-utils ~/Code/claw/flake-utils
(cd ~/Code/claw/flake-utils && git checkout 11707dc2f618dd54ca8739b309ec4fc024de578b)
git clone https://github.com/openclaw/nix-openclaw ~/Code/claw/nix-openclaw
git clone https://github.com/openclaw/nix-steipete-tools ~/Code/claw/nix-steipete-tools
```

---

## 5. Apply system config

```bash
cd ~/Code/nix
sudo darwin-rebuild switch --flake .
# Or explicit host:
sudo darwin-rebuild switch --flake '.#stella'
```

First run installs nix-darwin, Home Manager, Homebrew, mihomo; mirrors allow no proxy. If brew/mas fails, comment `masApps` or taps, add mihomo config, then run the same command again.

---

## 6. (Optional) Mihomo UI

Put UI in `~/.config/mihomo/ui/`:

```bash
git clone https://github.com/haishan/yacd.git ~/.config/mihomo/ui
```

---

## 7. (Optional) vars

Edit `vars/default.nix`: `hostname`, `username`, `mainSshAuthorizedKeys`, `initialHashedPassword` (use `nix-hash --type sha512` for fresh install).

---

## 8. Updates

```bash
cd ~/Code/nix
git pull
sudo darwin-rebuild switch --flake .
```

Same command for first and later runs. If mihomo config wasn’t ready at first deploy, add it and run again.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Determinate detected, aborting activation` | Expected; `nix.enable = false` is set. |
| mihomo won’t start | Check `~/.config/mihomo/config.yaml` exists and subscription URL is correct; re-run `darwin-rebuild switch`. |
| Homebrew install fails | Check mirrors in `modules/darwin/apps.nix`. |
| WeChat/SSL error | Comment masApps, add mihomo config, run switch again. |
| SSH key not used | Set `mainSshAuthorizedKeys` in `vars/default.nix`. |
| OpenClaw Gateway won’t start | If `~/.openclaw/openclaw.json` is empty, HM fallback writes minimal config; run `home-manager switch --flake .#stella` once. |

---

## ~/ 与 ~/Code 目录约定

Purpose of top-level dirs under `~/` and how they're organized.

### By purpose

**System / runtime (don't touch)**

| Dir/file | Purpose | Action |
|----------|---------|--------|
| `.cache/` | App caches (bat, nix eval-cache) | Keep |
| `.config/` | App config (mostly Home Manager) | Keep |
| `.local/` | Local state (nix profile, etc.) | Keep |
| `.nix-defexpr` / `.nix-profile` | Nix expr and profile links | Keep |
| `Library/`, `Applications/` | macOS / HM apps | Keep |
| `Desktop/` … `Public/` | macOS user dirs | Keep |

**Secrets (don't touch)**

| Dir | Purpose |
|-----|---------|
| `.ssh/` | SSH keys and config |
| `.secrets/` | Private keys / secrets |

**App data (keep as needed)**

| Dir | Purpose |
|-----|---------|
| `.codex/`, `.cursor/` | AI/IDE data |
| `.openclaw/` | OpenClaw runtime |
| `Zotero/` | Zotero library |

**Config / code (under ~/Code)**

| Path | Purpose |
|------|---------|
| **~/Code/nix** | Nix config (nix-darwin + HM); darwin-rebuild entry |
| **~/Code/claw** | Path deps (flake-utils, nix-openclaw, nix-steipete-tools) |
| **~/Code/nix/misc** | Non-eval assets (e.g. certs/ for PKI). |
| **~/Code/terminal_mcp** | Terminal MCP server (Go) |
| **~/Code/mcp-filesystem-python** | MCP filesystem server (Python) |
| **~/Code/openclaw_sandbox** | OpenClaw workspace (optional; was ~/openclaw_sandbox) |

Config and code live under **~/Code** for backup and clarity.

**Go cache (keep at ~)**

| Path | Purpose |
|------|---------|
| **~/go** | Go module cache (GOPATH/GOMODCACHE). Do not move; migration breaks `go build` / `go run`. |

**Backups and misc**

| Path | Purpose |
|------|---------|
| **~/Code/nix/archive/** | Home Manager and other backups (e.g. `zshrc.home-manager.backup`). |
| **~/Code/nix/misc/openclaw_research_sandbox.sb** | Sandbox profile (moved from ~). |

### How it was done

- Create `~/Code`; move former `~/nix` → `~/Code/nix`, `~/claw` → `~/Code/claw`.
- In nix: path inputs → `path:/Users/sue/Code/claw/<name>`; docs updated to ~/Code/nix, ~/Code/claw.
- Run darwin-rebuild from `~/Code/nix`.

### Notes

- Home Manager `home.homeDirectory` is `/Users/<username>` (vars); independent of repo path.
- Nix only needs path in flake.nix; ensure `~/Code/claw` subdirs exist.
- **~/bin** has been removed; PATH uses **~/.local/bin** only (see `home/base/core/shells/default.nix`).
