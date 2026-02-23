# macOS 新机部署指南

适用于 MacBook Air M4（`aarch64-darwin`），技术栈为 Determinate Nix + nix-darwin + Home Manager。

## 代理与国内网络说明

- **First deploy without proxy**: Nix uses substituter mirrors, Homebrew uses BFSU mirror. One `darwin-rebuild switch` deploys mihomo (package + launchd + config link); no separate install.
- **mihomo via Nix**: Package, env vars, `~/.config/mihomo/config.yaml` link, launchd are in `home/darwin/services/mihomo/default.nix`. Prepare config in repo (step 3); launchd starts mihomo on login.
- **Path inputs**: OpenClaw deps are path inputs (no GitHub at eval). Clone them once (with proxy if needed), then deploy.
- **brew/mas errors**: Comment out `masApps` or some taps to finish first deploy; add mihomo config, then run the same `darwin-rebuild switch` again.
- **GitHub access** (e.g. `nix flake update`): Use mihomo sessionVariables in shell, or set `http-proxy` / `https-proxy` in `~/.config/nix/nix.conf`.

## 前提条件

- Fresh macOS, user `sue` (match `vars/default.nix` `username`).

---

## 0. SSH Key（克隆仓库前）

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

## 1. 安装 Nix（Determinate）

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Restart terminal or `source /etc/nix/profile/nix.sh`.

---

## 2. 克隆配置仓库

```bash
mkdir -p ~/Code
cd ~/Code
git clone git@github.com:aesophsu/nix.git nix
cd nix
```

---

## 3. 准备 Mihomo 配置（其余由 Nix 部署）

Nix (Home Manager) deploys mihomo in step 5. Prepare config in repo (subscription URL/token; do not commit secrets):

```bash
cp home/darwin/services/mihomo/config.yaml.example home/darwin/services/mihomo/config.yaml
# Edit and add subscription URL, or use config.local.yaml (higher priority, often .gitignored)
```

After step 5, launchd starts mihomo automatically.

---

## 4. （可选）准备 OpenClaw path inputs

OpenClaw uses path inputs so the daemon doesn’t hit GitHub. Clone with proxy if needed (see `flake.nix`):

```bash
mkdir -p ~/Code/claw
git clone https://github.com/numtide/flake-utils ~/Code/claw/flake-utils
(cd ~/Code/claw/flake-utils && git checkout 11707dc2f618dd54ca8739b309ec4fc024de578b)
git clone https://github.com/openclaw/nix-openclaw ~/Code/claw/nix-openclaw
git clone https://github.com/openclaw/nix-steipete-tools ~/Code/claw/nix-steipete-tools
```

---

## 5. 应用系统配置

```bash
cd ~/Code/nix
sudo darwin-rebuild switch --flake .
# Or explicit host:
sudo darwin-rebuild switch --flake '.#stella'
```

First run installs nix-darwin, Home Manager, Homebrew, mihomo; mirrors allow no proxy. If brew/mas fails, comment `masApps` or taps, add mihomo config, then run the same command again.

---

## 6. （可选）安装 Mihomo UI

Put UI in `~/.config/mihomo/ui/`:

```bash
git clone https://github.com/haishan/yacd.git ~/.config/mihomo/ui
```

---

## 7. （可选）修改 `vars`

Edit `vars/default.nix`: `hostname`, `username`, `mainSshAuthorizedKeys`, `initialHashedPassword` (use `nix-hash --type sha512` for fresh install).

---

## 8. 后续更新

```bash
cd ~/Code/nix
git pull
sudo darwin-rebuild switch --flake .
```

Same command for first and later runs. If mihomo config wasn’t ready at first deploy, add it and run again.

---

## 故障排查

| 问题 | 处理方式 |
|---|---|
| `Determinate detected, aborting activation` | Expected; `nix.enable = false` is set. |
| mihomo won’t start | Check `~/.config/mihomo/config.yaml` exists and subscription URL is correct; re-run `darwin-rebuild switch`. |
| Homebrew install fails | Check mirrors in `modules/darwin/apps.nix`. |
| WeChat/SSL error | Comment masApps, add mihomo config, run switch again. |
| SSH key not used | Set `mainSshAuthorizedKeys` in `vars/default.nix`. |
| OpenClaw Gateway won’t start | If `~/.openclaw/openclaw.json` is empty, HM fallback writes minimal config; run `home-manager switch --flake .#stella` once. |

---

## `~/` 与 `~/Code` 目录约定

说明 `~/` 顶层目录用途及整理规则。

### 按用途分类

**系统 / 运行时目录（不要随意移动）**

| 路径 | 说明 | 建议 |
|---|---|---|
| `.cache/` | App caches (bat, nix eval-cache) | Keep |
| `.config/` | App config (mostly Home Manager) | Keep |
| `.local/` | Local state (nix profile, etc.) | Keep |
| `.nix-defexpr` / `.nix-profile` | Nix expr and profile links | Keep |
| `Library/`, `Applications/` | macOS / HM apps | Keep |
| `Desktop/` … `Public/` | macOS user dirs | Keep |

**Secrets（不要提交）**

| 路径 | 说明 |
|---|---|
| `.ssh/` | SSH keys and config |
| `.secrets/` | Private keys / secrets |

**应用数据（按需保留）**

| 路径 | 说明 |
|---|---|
| `.codex/`, `.cursor/` | AI/IDE data |
| `.openclaw/` | OpenClaw runtime |
| `Zotero/` | Zotero library |

**配置 / 代码（统一放在 `~/Code`）**

| 路径 | 说明 |
|---|---|
| **~/Code/nix** | Nix config (nix-darwin + HM); darwin-rebuild entry |
| **~/Code/claw** | Path deps (flake-utils, nix-openclaw, nix-steipete-tools) |
| **~/Code/nix/misc** | Non-eval assets (e.g. certs/ for PKI). |
| **~/Code/terminal_mcp** | Terminal MCP server (Go) |
| **~/Code/mcp-filesystem-python** | MCP filesystem server (Python) |
| **~/Code/openclaw_sandbox** | OpenClaw workspace (optional; was ~/openclaw_sandbox) |

配置与代码统一放在 `~/Code`，便于备份与管理。

**Go 缓存（保留在 `~`）**

| 路径 | 说明 |
|---|---|
| **~/go** | Go module cache (GOPATH/GOMODCACHE). Do not move; migration breaks `go build` / `go run`. |

**备份与杂项**

| 路径 | 说明 |
|---|---|
| **~/Code/nix/archive/** | Home Manager and other backups (e.g. `zshrc.home-manager.backup`). |
| **~/Code/nix/misc/openclaw_research_sandbox.sb** | Sandbox profile (moved from ~). |

### 调整方式（已完成）

- Create `~/Code`; move former `~/nix` → `~/Code/nix`, `~/claw` → `~/Code/claw`.
- In nix: path inputs → `path:/Users/sue/Code/claw/<name>`; docs updated to ~/Code/nix, ~/Code/claw.
- Run darwin-rebuild from `~/Code/nix`.

### 说明

- Home Manager `home.homeDirectory` is `/Users/<username>` (vars); independent of repo path.
- Nix only needs path in flake.nix; ensure `~/Code/claw` subdirs exist.
- **~/bin** has been removed; PATH uses **~/.local/bin** only (see `home/base/core/shells/default.nix`).
