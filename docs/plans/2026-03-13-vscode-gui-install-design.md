# VS Code GUI Install Design

**Goal:** Install the official Microsoft Visual Studio Code desktop application on this macOS
machine declaratively through the existing Nix-managed GUI application workflow.

**Architecture:** Reuse the current `modules/system/darwin/apps.nix` `homebrew.casks` list as the
single source of truth for rolling GUI apps. Add the `visual-studio-code` cask there and activate
the change with `darwin-rebuild switch --flake .#stella` so future rebuilds preserve the
installation.

**Tech Stack:** Nix, nix-darwin, Homebrew casks

---

## Decision

- Use the existing Homebrew cask layer for this GUI app instead of imperative `brew install`.
- Install the official Microsoft build via the `visual-studio-code` cask.
- Keep the change in the shared Darwin apps module so the machine state stays declarative.

## Why

- This repository already treats rolling macOS GUI software as a Homebrew-managed exception.
- Adding one cask is the smallest change that matches the current system architecture.
- A declarative entry avoids runtime drift and lets later rebuilds re-install or upgrade VS Code.

## Verification

- Confirm `visual-studio-code` is present in `modules/system/darwin/apps.nix`.
- Run `darwin-rebuild switch --flake .#stella`.
- Confirm Homebrew reports the VS Code cask as installed.
