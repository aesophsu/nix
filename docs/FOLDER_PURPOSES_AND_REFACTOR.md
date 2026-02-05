# Folder roles and refactor notes

## 1. Top-level

| Dir/file | Role | Used by |
|----------|------|---------|
| **outputs/** | Flake output entry: load per-arch (aarch64-darwin/src/*.nix), merge darwinConfigurations, packages, checks, devShells | flake.nix → import ./outputs |
| **modules/** | System config (nix-darwin): base + darwin | stella.nix → modules/darwin, hosts/darwin-stella; darwin → modules/base |
| **home/** | User config (Home Manager): base + darwin (mihomo, openclaw, postgresql) | stella.nix → home/darwin → home/base |
| **hosts/** | Per-host overrides: hostname, home SSH, etc. | stella.nix → hosts/darwin-stella |
| **lib/** | Shared: macosSystem, relativeToRoot, scanPaths, attrs, openclaw-package | outputs/default.nix → mylib, genSpecialArgs |
| **vars/** | Central: username, hostname, SSH, networking | outputs → myvars; modules via args |
| **overlays/** | Nixpkgs overlays (default.nix only → empty list) | modules/base/overlays.nix |
| **misc/** | Non-eval assets (e.g. certs); security.nix uses ecc-ca.crt | modules/base/security.nix |
| **docs/** | Docs | Human |
| **.github/** | CI | GitHub Actions |

---

## 2. Folder details

### outputs/

- **Role**: Single flake output entry; load host fragments per system (aarch64-darwin only for now), merge.
- **Contents**: default.nix (mylib, myvars, genSpecialArgs, call aarch64-darwin → darwinConfigurations/packages/checks/devShells/formatter); aarch64-darwin/default.nix (haumea load src/*.nix); aarch64-darwin/src/stella.nix (stella module list, overlay, HM).
- **Verdict**: Clear; no change.

### modules/

- **Role**: nix-darwin system modules (platform/host-agnostic “capabilities”).
- **base/**: Shared (fonts, nix, overlays, packages, security, users); pulled in by darwin default.
- **darwin/**: macOS (Homebrew, proxy, GUI, Nix core, SSH, defaults, openclaw placeholder, security, users).
- **Verdict**: Roles clear; keep.

### home/

- **Role**: Home Manager; split by platform.
- **base/**: Cross-platform (core: git, neovim, python, starship, theme, shells; home.nix state/username).
- **darwin/**: macOS; default.nix scanPaths loads mihomo, openclaw, postgresql.
- **Verdict**: Simple entry; keep.

### hosts/

- **Role**: Per-hostname overrides (hostname, computer name, home SSH identity).
- **Contents**: darwin-stella (default.nix hostname, home.nix GitHub identityFile).
- **Verdict**: Add host = copy darwin-stella → darwin-<name>, add src/<name>.nix; structure fine.

### lib/

- **Role**: Flake/output/host-agnostic logic.
- **Contents**: attrs, macosSystem, relativeToRoot/scanPaths (default.nix), openclaw-package.nix.
- **Verdict**: openclaw-package is app-specific but fits here for outputs; optional later: lib/openclaw/ if more helpers.

### vars/

- **Role**: Single place for username, hostname, SSH, networking.
- **Contents**: default.nix (user, hashed password, SSH keys), networking.nix (mihomo, DNS, host net, knownHosts).
- **Verdict**: Keep.

### overlays/

- **Role**: Custom Nixpkgs overlays; modules/base/overlays.nix imports.
- **Now**: Only default.nix (no other .nix) → empty overlay list.
- **Verdict**: Keep; add overlay = new .nix here.

### misc/

- **Role**: Non-eval assets.
- **misc/certs/**: PKI (ECC CA, server cert, gen-certs.sh); private keys not in repo; security.nix uses ecc-ca.crt.
- **Verdict**: Keep; add similar assets under misc.

### docs/

- **Role**: Deploy, OpenClaw, flake analysis, this doc.
- **Verdict**: Keep; README.md index exists.

---

## 3. Refactor suggestions (priority)

1. **docs index**: docs/README.md (done) listing each doc.
2. **overlays**: Short overlays/README.md: “Referenced by modules/base/overlays.nix; no extra overlay yet; add .nix here to add one.”
3. **Topology**: Don’t merge; outputs/modules/home/hosts/lib/vars are already aligned with common nix-darwin/HM usage. Merging (e.g. hosts into modules) blurs “host override” vs “capability.”
4. **certs in misc**: Done.
5. **No new top-level dirs**: outputs, modules, home, hosts, lib, vars, overlays, misc, docs are enough.

---

## 4. Ref graph

```
flake.nix
  └── outputs/default.nix
        ├── lib/ (mylib, openclaw-package via genSpecialArgs)
        ├── vars/ (myvars)
        └── outputs/aarch64-darwin/
              └── src/stella.nix
                    ├── modules/darwin, base
                    ├── hosts/darwin-stella
                    ├── home/darwin → home/base
                    ├── inputs.nix-openclaw (overlay + homeManagerModules)
                    └── genSpecialArgs → openclawPackageNoOracle
modules/base/overlays.nix → overlays/
modules/base/security.nix → misc/certs/ecc-ca.crt
```

---

## 5. Summary

| Item | Recommendation |
|------|----------------|
| Folder roles | As above; matches “outputs entry + modules/home by platform + hosts per host + lib/vars shared.” |
| Required | None; structure is fine long-term. |
| Optional | docs/README.md (done), overlays/README.md. |
| Avoid | Merging modules/home/hosts or adding extra top-level dirs. |
