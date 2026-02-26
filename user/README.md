# Home Manager 结构

单机 `stella` 使用的用户层配置（Home Manager），按职责拆分为共享层与 Darwin 层。

## 目录结构

```
user/
├── common/         # Shared (within this repo)
│   ├── core/      # packages, git, neovim, python, starship, theme, shells
│   └── home.nix   # stateVersion, username
└── darwin/        # macOS
    ├── default.nix      # entry; imports apps/services/profiles + base
    ├── apps/
    │   ├── default.nix
    │   └── gui.nix      # GUI app layer (currently mostly delegated to Homebrew profile)
    ├── profiles/
    │   ├── default.nix
    │   └── shell.nix    # dev shell/PATH tweaks
    └── services/
        ├── default.nix
        ├── mihomo/      # proxy (default.nix + config)
        └── postgresql/  # PostgreSQL 16 (default.nix)
```

`user/darwin/default.nix` 会引入 `../common/core` 与 `../common/home.nix`。Darwin 入口保留顶层模块自动扫描，并显式导入 `apps/`、`services/`、`profiles/` 以保证结构与导入顺序稳定。用户信息来自 `vars/default.nix`；当前主机为 `stella`（`--flake .#stella`）。
