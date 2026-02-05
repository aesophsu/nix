# Home Manager · Darwin (macOS)

macOS-only HM config; used with `hosts/darwin-stella`.

| Path | Role |
|------|------|
| default.nix | homeDirectory, xdg; imports ../base and scanPaths of this dir |
| shell.nix | Dev/temp shell |
| mihomo/ | [mihomo](https://github.com/MetaCubeX/mihomo): package, env, config, launchd |
| openclaw/ | [OpenClaw](https://openclaw.ai) (nix-openclaw): config, gateway, launchd, documents |
| postgresql/ | PostgreSQL 16 (Nixpkgs): package, data dir, launchd |

`default.nix` uses `mylib.scanPaths ./.`; home-modules in stella.nix: hosts/darwin-stella/home.nix, home/darwin, nix-openclaw.homeManagerModules.openclaw.

**Commands**: `darwin-rebuild switch --flake .` (full); `home-manager switch --flake .#stella` (HM only); `home-manager switch --rollback`.
