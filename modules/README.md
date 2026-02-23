# 系统模块结构（nix-darwin）

按平台拆分的系统层模块配置。

## 目录结构

```
modules/
├── base/              # Shared (all platforms)
│   ├── default.nix
│   ├── fonts.nix, nix.nix, overlays.nix, system-packages.nix, security.nix, users.nix
└── darwin/            # macOS
    ├── default.nix
    ├── apps.nix       # Homebrew, env, GUI/casks
    ├── broken-packages.nix
    ├── nix-determinate.nix, security.nix, ssh.nix, system.nix, users.nix
    ├── maintenance/   # Periodic/system maintenance tasks (launchd)
    │   ├── default.nix
    │   └── nix-store.nix
    └── profiles/      # Host-independent tuning profiles/overrides
        ├── default.nix
        └── storage-256g-aggressive.nix
```

`base/` 提供跨平台系统模块（字体、Nix、overlay、系统级包、安全、用户等）。
`darwin/` 提供 macOS 系统模块（Homebrew、代理、defaults、Determinate Nix 兼容、SSH、安全、用户），并按 `maintenance/`、`profiles/` 分组扩展。

当前主机入口 `stella` 会组合 `modules/darwin/` 与 `hosts/darwin-stella/`；`modules/darwin/default.nix` 再引入 `modules/base/`。
