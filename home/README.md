# Home Manager submodules

User config by platform and function.

## Structure

```
home/
├── base/           # Cross-platform
│   ├── core/      # git, neovim, python, starship, theme, shells
│   └── home.nix   # stateVersion, username
└── darwin/        # macOS
    ├── default.nix   # entry; scanPaths loads subdirs
    ├── shell.nix     # dev shell
    ├── mihomo/       # proxy (default.nix + config)
    ├── openclaw/     # OpenClaw (default.nix + documents)
    └── postgresql/   # PostgreSQL 16 (default.nix)
```

**base** is pulled in by darwin `default.nix` (`../base/core`, `../base/home.nix`). **darwin** entry uses `mylib.scanPaths`; user from `vars/default.nix`; host `stella` (`--flake .#stella`).
