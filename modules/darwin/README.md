# Nix-Darwin's Modules

本目录为 [Nix-Darwin](https://github.com/LnL7/nix-darwin) 的 macOS 模块，由 `outputs/aarch64-darwin/src/stella.nix` 通过 `modules/darwin` 与 `hosts/darwin-stella` 引入；`default.nix` 会再引入 `../base` 共享配置。

| 文件 | 说明 |
|------|------|
| **default.nix** | 入口，引入本目录所有模块及 `modules/base` |
| **apps.nix** | Homebrew、环境变量（代理/镜像）、GUI 应用与 casks |
| **system.nix** | 主机名、系统代理（networksetup）、时区、Dock/Finder/键盘等 defaults |
| **nix-core.nix** | Nix daemon 设置（experimental-features、镜像等） |
| **openclaw.nix** | 添加 nix-openclaw overlay，供 Home Manager 使用 |
| **security.nix** | PAM、Touch ID 等 |
| **ssh.nix** | SSH 服务与 knownHosts |
| **users.nix** | 用户与 SSH 公钥 |
| **broken-packages.nix** | 包兼容/补丁 |

更多结构见上级 [modules/README.md](../README.md)。

## 已知警告（可忽略）

执行 `darwin-rebuild switch` 时可能出现的无害警告：

| 警告 | 说明 |
|------|------|
| `builtins.toFile` / `options.json` | home-manager 上游 bug [#7935](https://github.com/nix-community/home-manager/issues/7935)，不影响功能 |
| `pnpm.fetchDeps: The package attribute is deprecated...` | nix-openclaw 构建 gateway 时触发，来自 nixpkgs 的 pnpm API 变更提示，不影响当前构建；上游改用 `fetchPnpmDeps` 后可消失 |
| bat `Dockerfile (with bash)` syntax | bat 语法高亮上游问题，不影响使用 |
