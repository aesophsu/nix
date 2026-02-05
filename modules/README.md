# System modules (nix-darwin)

Modular system config by platform.

## Structure

```
modules/
├── base/              # Shared (all platforms)
│   ├── default.nix
│   ├── fonts.nix, nix.nix, overlays.nix, packages.nix, security.nix, users.nix
└── darwin/            # macOS
    ├── default.nix
    ├── apps.nix       # Homebrew, env, GUI/casks
    ├── broken-packages.nix
    ├── nix-core.nix, openclaw.nix, security.nix, ssh.nix, system.nix, users.nix
```

**Base**: fonts, Nix settings, overlays, packages, security, users. **Darwin**: Homebrew, proxy, defaults, Nix core, SSH, openclaw placeholder, security, users.

**Usage**: stella.nix pulls in modules/darwin and hosts/darwin-stella; darwin default.nix pulls in base. Current host: aarch64-darwin, stella (MacBook Air M4).
