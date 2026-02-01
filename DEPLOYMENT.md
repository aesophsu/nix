# 重装系统后从头部署指南

适用于 MacBook Air M4 (aarch64-darwin)，使用 Determinate Nix + nix-darwin + Home Manager。

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

## 三、配置 Mihomo（代理）

`config.yaml` 含订阅 token，未纳入 git。需手动创建：

```bash
# 复制模板
cp home/darwin/mihomo/config.yaml.example home/darwin/mihomo/config.yaml

# 编辑并填入你的订阅 URL（含 token）
# 或使用 config.local.yaml（优先级更高）
# cp home/darwin/mihomo/config.yaml.example home/darwin/mihomo/config.local.yaml
```

---

## 四、应用系统配置

```bash
cd ~/nix
sudo darwin-rebuild switch --flake '.#stella'
```

首次会安装 nix-darwin、Home Manager、Homebrew 等，耗时较长。

---

## 五、可选：Mihomo 控制面板 UI

如需 Web 面板，将 UI 放到 `~/.config/mihomo/ui/`：

```bash
# 示例：yacd
git clone https://github.com/haishan/yacd.git ~/.config/mihomo/ui
```

---

## 六、可选：vars 个性化

根据机器修改 `vars/default.nix`：

- `hostname`：主机名（当前 `stella`）
- `username`：用户名（当前 `sue`）
- `mainSshAuthorizedKeys`：SSH 公钥（用于 `~/.ssh/authorized_keys`）
- `initialHashedPassword`：新装系统可设置 `nix-hash --type sha512` 生成的哈希密码

---

## 七、后续更新

```bash
cd ~/nix
git pull
sudo darwin-rebuild switch --flake '.#stella'
```

---

## 故障排查

| 问题 | 处理 |
|------|------|
| `Determinate detected, aborting activation` | 已设置 `nix.enable = false`，无需改动 |
| mihomo 无法启动 | 检查 `~/.config/mihomo/config.yaml` 是否存在且订阅 URL 正确 |
| Homebrew 安装失败 | 国内网络可检查 `modules/darwin/apps.nix` 中的镜像配置 |
| SSH 密钥未生效 | 确认 `vars/default.nix` 中 `mainSshAuthorizedKeys` 已配置 |
