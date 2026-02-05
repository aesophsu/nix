# 重装系统后从头部署指南

适用于 MacBook Air M4 (aarch64-darwin)，使用 Determinate Nix + nix-darwin + Home Manager。

## 中国大陆说明

- **首轮部署可不依赖代理**：Nix 使用国内 substituter 镜像，Homebrew 使用北外镜像；同一次 `darwin-rebuild switch` 会一并完成 mihomo 的 Nix 部署（包 + launchd + config 链接），无需先单独“安装”或“启动” mihomo。
- **mihomo 由 Nix 部署**：包、环境变量、`~/.config/mihomo/config.yaml` 的链接、launchd 均由 `home/darwin/mihomo/default.nix` 管理；你只需在仓库里准备 config 内容（步骤三），launchd 会在登录后自动启动 mihomo。
- **path 输入**：OpenClaw 相关为 path 输入，不经过 GitHub，首次需在能访问 GitHub 的环境下克隆到本地后再部署。
- **若 brew bundle 报错**：可先注释 `masApps` 或部分 taps 完成首次部署，在仓库中补好 mihomo config 后再次执行同一条 `darwin-rebuild switch`（无需改其它配置）。
- **需要拉 GitHub 时**（如 `nix flake update`）：终端里 mihomo 的 sessionVariables 会提供代理；或先在 `~/.config/nix/nix.conf` 中配置 `http-proxy` / `https-proxy` 再执行。

## 前置条件

- 新装 macOS，已创建用户 `sue`（与 `vars/default.nix` 中 `username` 一致）

---

## 零、配置 SSH 密钥（克隆前必做）

重装后需先生成 SSH 密钥并添加到 GitHub，才能用 `git clone git@github.com:...` 克隆。

```bash
# 1. 生成密钥（一路回车，或设置密码）
ssh-keygen -t ed25519 -C "aesophsu@gmail.com"

# 2. 启动 ssh-agent 并添加密钥
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 3. 复制公钥到剪贴板（macOS）
pbcopy < ~/.ssh/id_ed25519.pub
```

然后打开 [GitHub → Settings → SSH and GPG keys](https://github.com/settings/keys)，点击 **New SSH key**，粘贴公钥并保存。

```bash
# 4. 测试连接（首次会提示确认 github.com 指纹，输入 yes）
ssh -T git@github.com
```

---

## 一、安装 Nix（Determinate）

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

安装完成后**重新打开终端**或执行 `source /etc/nix/profile/nix.sh`。

---

## 二、克隆配置仓库

```bash
cd ~
git clone git@github.com:aesophsu/nix.git
cd nix
```

---

## 三、准备 Mihomo 配置（代理由 Nix 部署）

mihomo 的**安装、launchd、环境变量、config 链接**均由 Nix（Home Manager）在步骤五中一并部署。你只需在仓库里准备好 config 文件内容（含订阅 token，不提交到 git）：

```bash
# 复制模板
cp home/darwin/mihomo/config.yaml.example home/darwin/mihomo/config.yaml

# 编辑并填入你的订阅 URL（含 token）
# 或使用 config.local.yaml（优先级更高，且通常被 .gitignore）
# cp home/darwin/mihomo/config.yaml.example home/darwin/mihomo/config.local.yaml
```

执行步骤五后，launchd 会自动启动 mihomo，无需手动“安装”或“启动”。

---

## 四、（可选）OpenClaw 与 path 输入

若需使用 OpenClaw，本仓库使用 **path 输入** 避免 Nix daemon 直连 GitHub。首次需在**已开代理**的终端克隆以下仓库到本地后再执行后续步骤（见 `flake.nix` 内注释）：

```bash
git clone https://github.com/openclaw/nix-openclaw /Users/sue/nix-openclaw
git clone https://github.com/numtide/flake-utils /Users/sue/flake-utils
git clone https://github.com/openclaw/nix-steipete-tools /Users/sue/nix-steipete-tools
```

---

## 五、应用系统配置

```bash
cd ~/nix
sudo darwin-rebuild switch --flake .
# 或显式指定主机名
sudo darwin-rebuild switch --flake '.#stella'
```

首次会安装 nix-darwin、Home Manager、Homebrew、**以及 mihomo（包 + launchd + config 链接）** 等，耗时较长。国内已配置镜像，本次执行**不依赖代理**即可完成；mihomo 会在本次或下次 switch 中由 Nix 部署，launchd 在登录后自动启动（若已按步骤三准备好 config）。

**若 brew bundle 报错**（如 GitHub tap、mas 连 itunes.apple.com 失败）：可先注释 `modules/darwin/apps.nix` 中的 `masApps` 或部分 taps 完成首次部署；在仓库中补好 mihomo config（步骤三）后，再次执行同一条上述命令即可，无需改其它配置。

---

## 六、可选：Mihomo 控制面板 UI

如需 Web 面板，将 UI 放到 `~/.config/mihomo/ui/`：

```bash
# 示例：yacd
git clone https://github.com/haishan/yacd.git ~/.config/mihomo/ui
```

---

## 七、可选：vars 个性化

根据机器修改 `vars/default.nix`：

- `hostname`：主机名（当前 `stella`）
- `username`：用户名（当前 `sue`）
- `mainSshAuthorizedKeys`：SSH 公钥（用于 `~/.ssh/authorized_keys`）
- `initialHashedPassword`：新装系统可设置 `nix-hash --type sha512` 生成的哈希密码

---

## 八、后续更新

```bash
cd ~/nix
git pull
sudo darwin-rebuild switch --flake .
```

**首轮运行与再次运行**：使用同一套配置、同一条命令，无需在“首轮”和“再次”之间改配置。mihomo 由 Nix 在每次 switch 时部署（包 + launchd + config 链接）；若首轮时尚未准备 mihomo config，补好后再执行一次上述命令即可。

---

## 故障排查

| 问题 | 处理 |
|------|------|
| `Determinate detected, aborting activation` | 已设置 `nix.enable = false`，无需改动 |
| mihomo 无法启动 | mihomo 由 Nix 部署（home/darwin/mihomo）；检查 `~/.config/mihomo/config.yaml` 是否存在且订阅 URL 正确，补好后重新执行 `darwin-rebuild switch` |
| Homebrew 安装失败 | 国内网络可检查 `modules/darwin/apps.nix` 中的镜像配置 |
| WeChat 安装 SSL 错误 | 先注释 masApps 完成部署，补好 mihomo config 后再次 `darwin-rebuild switch`，无需改其它配置 |
| SSH 密钥未生效 | 确认 `vars/default.nix` 中 `mainSshAuthorizedKeys` 已配置 |
| OpenClaw Gateway 无法启动 | 检查 `~/.openclaw/openclaw.json` 是否为空；Home Manager 的 fallback 会写入最小配置（gateway.mode=local），可执行一次 `home-manager switch --flake .#stella` 触发 |
