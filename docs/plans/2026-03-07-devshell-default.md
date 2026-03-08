# DevShell Implementation Plan
> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a default `devShells.aarch64-darwin.default` so `direnv use flake` resolves successfully and exposes repo-maintenance CLI tools.

**Architecture:** Keep the change in `outputs/default.nix` so the flake exports a conventional default development shell without changing `darwinConfigurations` or user/system package layering. Build the shell with `pkgs.mkShell` and a small curated tool list already expected for Nix repo maintenance.

**Tech Stack:** Nix flakes, nixpkgs, direnv, nix-direnv

---

### Task 1: Add default dev shell output

**Files:**
- Modify: `outputs/default.nix`
- Verify: `.envrc`, `flake.nix`

**Step 1: Inspect available package names in current nixpkgs**
- Confirm the exact attribute names for repo-maintenance tools before editing.

**Step 2: Write the minimal output change**
- Add `devShells.aarch64-darwin.default = pkgs.mkShell { packages = [ ... ]; };`.
- Keep the tool list focused on repository maintenance and Nix authoring.

**Step 3: Verify flake evaluation**
- Run `nix develop .#default --command true` or `nix eval .#devShells.aarch64-darwin.default --apply builtins.typeOf`.
- Run `direnv allow` / `direnv reload` behavior check from the repo root.

**Step 4: Confirm no unrelated output regressions**
- Run a targeted `nix flake show` or equivalent evaluation command if sandbox permits.
