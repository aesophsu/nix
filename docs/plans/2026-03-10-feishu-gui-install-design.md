# Feishu GUI Install Design

**Goal:** Install the mainland China Feishu desktop client on this macOS machine declaratively
through the existing Nix-managed Homebrew GUI layer.

**Architecture:** Reuse the current `system/darwin/apps.nix` Homebrew cask list as the single source
of truth for GUI apps. Add the `feishu` cask there and activate the change with
`darwin-rebuild switch` so future rebuilds keep Feishu installed and upgradable.

**Tech Stack:** Nix, nix-darwin, Homebrew casks

---

## Decision

- Use the existing Homebrew cask workflow instead of imperative `brew install`.
- Install the mainland China client via the `feishu` cask, not the international `lark` cask.
- Keep the change system-wide in the existing Darwin apps module.

## Why

- This repository already treats rolling GUI applications as Homebrew-managed exceptions.
- Adding one cask is the smallest change that matches the current architecture.
- A declarative entry avoids runtime drift and keeps rebuilds reproducible.

## Verification

- Confirm `feishu` is present in `system/darwin/apps.nix`.
- Run `darwin-rebuild switch` for this host.
- Check that the rebuild finishes successfully and the resulting configuration still evaluates
  cleanly.
