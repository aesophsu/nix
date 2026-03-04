# macOS 新机部署指南

适用于 MacBook Air M4（`aarch64-darwin`），技术栈为 Determinate Nix + nix-darwin + Home Manager。

## 代理与国内网络说明

- **First deploy without proxy**: Nix uses substituter mirrors. One `darwin-rebuild switch` deploys mihomo (package + launchd + config link); no separate install.
- **mihomo via Nix**: Package, env vars, `~/.config/mihomo/config.yaml` link, launchd are in `user/darwin/services/mihomo/default.nix`. Prepare config in repo (step 3); launchd starts mihomo on login.
- **system proxy**: activation sets macOS network services to local mihomo proxy (`127.0.0.1:7890/7891`) by default (`proxy.policy.systemDefault = "on"`).
- **runtime switch**: use `proxy-on` / `proxy-off` / `proxy-status` to manage system proxy without editing Nix files.
- **GitHub access** (e.g. `nix flake update`): Use mihomo sessionVariables in shell, or set `http-proxy` / `https-proxy` in `~/.config/nix/nix.conf`.
- **Toolchains**: Node/Python are pinned in one place (`myvars.toolchains.*`): `node.package = "nodejs_22"`, `python.package = "python312"`.
- **Node toolchain**: Use Corepack to manage pnpm; avoid mixing `nvm`/`volta` with Nix Node.
- **Unified CLI source**: `python / uv / ruff / git / nodejs / docker / jq / curl` are managed in `user/common/core/tooling/*`; `direnv` remains in `user/common/core/packages.nix` (Docker is CLI+Compose only, no Docker Desktop).

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
cp user/darwin/services/mihomo/config.yaml.example user/darwin/services/mihomo/config.yaml
# Edit and add subscription URL, or use config.local.yaml (higher priority, often .gitignored)
```

After step 5, launchd starts mihomo automatically.

---

## 4. 应用系统配置

```bash
cd ~/Code/nix
sudo darwin-rebuild switch --flake .
# Or explicit host:
sudo darwin-rebuild switch --flake '.#stella'
```

First run installs nix-darwin, Home Manager, Homebrew, mihomo. If Homebrew install fails on first run, add mihomo config and rerun the same command.

## 4.1 代理控制（运行时）

```bash
proxy-status
proxy-off
proxy-on
```

`proxy-on` / `proxy-off` 仅切换 macOS 系统代理，不改写配置文件；下一次 `darwin-rebuild switch` 会再次按 `proxy.policy.systemDefault` 应用默认状态。

---

## 5. （可选）安装 Mihomo UI

Put UI in `~/.config/mihomo/ui/`:

```bash
git clone https://github.com/haishan/yacd.git ~/.config/mihomo/ui
```

---

## 6. （可选）修改 `vars`

Edit `vars/default.nix`: `hostname`, `username`, `mainSshAuthorizedKeys`, `initialHashedPassword` (use `nix-hash --type sha512` for fresh install).

---

## 7. 后续更新

```bash
cd ~/Code/nix
git pull
sudo darwin-rebuild switch --flake .
```

Same command for first and later runs. If mihomo config wasn’t ready at first deploy, add it and run again.

### 可选：仅做评估与 smoke 校验（不构建系统）

```bash
cd ~/Code/nix
nix flake check --no-build
nix build --no-link .#checks.aarch64-darwin.smoke-eval
```

### Node / pnpm（Corepack）

```bash
node -v
corepack enable
corepack prepare pnpm@latest --activate   # optional, pin a version per project if needed
pnpm install --frozen-lockfile
```

---

## 故障排查

| 问题 | 处理方式 |
|---|---|
| `Determinate detected, aborting activation` | Expected; `nix.enable = false` is set. |
| mihomo won’t start | Check `~/.config/mihomo/config.yaml` exists and subscription URL is correct; re-run `darwin-rebuild switch`. |
| Homebrew install fails | Check proxy env/homebrew settings in `system/darwin/apps.nix`; add mihomo config, then run switch again. |
| WeChat/SSL error | Ensure mihomo is running and system proxy is active, then run switch again. |
| SSH key not used | Set `mainSshAuthorizedKeys` in `vars/default.nix`. |

推荐排障顺序：`proxy-status` -> `launchctl print gui/$(id -u)/mihomo` -> `darwin-rebuild switch --flake .`

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
| `Zotero/` | Zotero library |

**配置 / 代码（统一放在 `~/Code`）**

| 路径 | 说明 |
|---|---|
| **~/Code/nix** | Nix config (nix-darwin + HM); darwin-rebuild entry |
| **~/Code/nix/misc** | Non-eval assets (e.g. certs/ for PKI). |
| **~/Code/terminal_mcp** | Terminal MCP server (Go) |
| **~/Code/mcp-filesystem-python** | MCP filesystem server (Python) |

配置与代码统一放在 `~/Code`，便于备份与管理。

**Go 缓存（保留在 `~`）**

| 路径 | 说明 |
|---|---|
| **~/go** | Go module cache (GOPATH/GOMODCACHE). Do not move; migration breaks `go build` / `go run`. |

### 调整方式（已完成）

- Create `~/Code`; move former `~/nix` → `~/Code/nix`.
- Run darwin-rebuild from `~/Code/nix`.

### 说明

- Home Manager `home.homeDirectory` is `/Users/<username>` (vars); independent of repo path.
- **~/bin** has been removed; PATH uses **~/.local/bin** only (see `user/common/core/shells/default.nix`).

## 架构说明（当前）

- `outputs/default.nix` 直接装配单机 `stella`（不再使用 host registry / 文档生成检查）。
- `outputs/darwin/default.nix` 直接组合 `system/`、`user/` 与 `hosts/stella/`，同时挂载 `outputs/darwin/tests/default.nix`。
- `checks.<system>.smoke-eval` 为统一 smoke 检查命名；`checks.<system>.pre-commit` 为统一 pre-commit 检查命名。

### 模块边界（重构后）

- `vars/networking/`：按领域拆分 `proxy` / `mihomo` / `dns` / `hosts` / `ssh`，由 `vars/networking/default.nix` 聚合。
- `system/darwin/system/`：按行为拆分 `proxy-tools` / `activation` / `defaults-ui` / `input` / `security-pam` / `timezone`，由 `system/darwin/system.nix` 聚合。
- `user/common/core/`：工具按职责拆到 `tooling/toolchain.nix`、`tooling/vcs.nix`、`tooling/infra.nix`；`packages.nix` 仅保留基础 CLI 与 `direnv`，CLI 体验配置在 `cli-experience.nix`。

### 单一声明约束

- Node/Python 版本仅在 `vars/toolchains.nix` 定义。
- `python / uv / ruff / git / nodejs / docker / jq / curl` 仅在 `user/common/core/tooling/*.nix` 声明；`direnv` 仅在 `user/common/core/packages.nix` 声明。
- 代理脚本逻辑仅在 `system/darwin/system/proxy-tools.nix`。

### 关键目录显式导入

- `system/darwin/.imports.nix`：固定 Darwin 核心模块导入顺序。
- `user/common/core/.imports.nix`：固定 core 模块导入顺序。
