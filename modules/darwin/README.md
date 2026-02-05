# Darwin modules (macOS)

[nix-darwin](https://github.com/LnL7/nix-darwin) macOS modules. Loaded from `outputs/aarch64-darwin/src/stella.nix` (modules/darwin + hosts/darwin-stella); default.nix also pulls modules/base.

| File | Role |
|------|------|
| default.nix | Entry; all modules here + modules/base |
| apps.nix | Homebrew, env (proxy/mirrors), GUI/casks |
| system.nix | Hostname, proxy (networksetup), timezone, Dock/Finder/keyboard defaults |
| nix-core.nix | Nix daemon (experimental-features, mirrors) |
| openclaw.nix | Placeholder; overlay in stella.nix |
| security.nix | PAM, Touch ID |
| ssh.nix | SSH service, knownHosts |
| users.nix | Users, SSH keys |
| broken-packages.nix | Compatibility/patches |

See [modules/README.md](../README.md) for layout.

**Harmless warnings**: builtins.toFile/options.json (HM [#7935](https://github.com/nix-community/home-manager/issues/7935)); pnpm.fetchDeps deprecation (nix-openclaw build); bat Dockerfile syntax.
