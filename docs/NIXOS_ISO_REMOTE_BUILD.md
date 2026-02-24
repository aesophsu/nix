# 远程 Linux 构建 NixOS ISO（macOS 上传工作区）

适用于在 macOS（当前主机 `stella`）上维护 flake，但将 `x86_64-linux` 的 NixOS installer ISO 构建放到远程 Linux 主机执行。

## 背景（为何改为显式远程构建）

本仓库不再推荐依赖本机 `nix build` 透明派发到远程 builder。原因：

- 行为不够显式：本地命令可能悄悄跑到远端，排错成本高
- 构建环境边界不清楚：很难快速判断是本地问题还是远端问题
- 产物管理分散：ISO 在远端 store，下载与命名流程不统一

现在改为标准流程：

1. 本地 `rsync` 上传当前工作区
2. 远程 Linux 执行 `nix build`
3. 本地自动下载 ISO 到 `archive/iso-out/`

## 适用场景

- 在 macOS 上维护 `/Users/sue/Code/nix`
- 构建 `packages.x86_64-linux.<isoAlias>`（例如 `shaka-installer-iso`）
- 远程 Linux 主机具备 `nix`、`rsync`、`bash`、SSH 访问能力

## 前置条件

本地：

- `nix`
- `git`
- `ssh`
- `rsync`

远程 Linux：

- `nix`（开启 flakes）
- `bash`
- `rsync`
- 足够磁盘空间（ISO 构建可能较大）

SSH：

- 建议在 `~/.ssh/config` 中配置 host alias，减少脚本参数复杂度

## 配置方式（推荐：env.local + CLI 参数）

复制示例文件：

```bash
cp scripts/build-nixos-iso-remote.env.example scripts/build-nixos-iso-remote.env.local
```

编辑 `scripts/build-nixos-iso-remote.env.local`（已在 `.gitignore` 中忽略）：

```bash
NIX_ISO_REMOTE_HOST="your-linux-builder"
NIX_ISO_REMOTE_DIR="/srv/nix-iso-build"
```

脚本参数优先级高于 env：

- `--host`
- `--remote-dir`
- `--iso`
- `--local-out-dir`
- `--flake-subpath`

## 标准命令

### 先看 dry-run（推荐）

```bash
scripts/build-nixos-iso-remote.sh --dry-run \
  --host <ssh-host> \
  --remote-dir <remote-dir>
```

### 实际构建（默认 ISO：`shaka-installer-iso`）

```bash
scripts/build-nixos-iso-remote.sh \
  --host <ssh-host> \
  --remote-dir <remote-dir> \
  --iso shaka-installer-iso
```

### 保留远端工作目录（便于排错）

```bash
scripts/build-nixos-iso-remote.sh \
  --host <ssh-host> \
  --remote-dir <remote-dir> \
  --keep-remote
```

## 产物位置

默认本地下载路径：

- `archive/iso-out/<iso-alias>-<run-id>.iso`

脚本会打印：

- 远端 store path
- 本地 ISO 路径
- 本地 ISO 大小
- 本地 SHA256

## 工作区上传语义（重要）

脚本默认上传“当前工作区”，包括未提交修改（不是强制已提交版本）。

- 如果工作区是 dirty，脚本会打印 warning，但继续执行
- 日志中会记录当前 commit short SHA 和 `clean/dirty` 状态

这有利于快速迭代，但可复现性低于“只构建已提交版本”。如需严格复现，请先提交改动后再运行脚本。

## 故障排查

### 1) SSH 失败

- 检查 `--host` 是否正确（建议用 SSH config alias）
- 检查密钥与 `ssh -T` / `ssh <host>` 是否可用

### 2) 远端缺少 `nix` / `rsync` / `bash`

脚本预检会失败并提示缺失命令。

### 3) ISO alias 不存在

脚本会在本地先校验 flake 输出别名（例如 `shaka-installer-iso`、`macbookpro11-2-installer-iso`）。

### 4) 下载失败

脚本会保留远端工作目录，便于手动登录远端排查构建产物与日志。

### 5) 构建很慢 / 拉取很多依赖

- 先检查远端缓存与网络
- 确认远端 Linux 可访问 `cache.nixos.org` 或你配置的 substituters

## 安全与清理说明

- 默认成功后会删除远端“工作目录”（上传的源码副本）
- 不会删除远端 Nix store 中的构建产物
- 使用 `--keep-remote` 可保留远端工作目录以便排查
