# PATH Priority Adjustment Implementation Plan
> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Nix-managed `node`/`npm`/`git`/`jq` resolve before Homebrew, system, and manually installed npm global binaries in interactive shells.

**Architecture:** Adjust the shell profile fragment that currently prepends `~/.local/npm/bin`, `/opt/homebrew/bin`, and `/usr/local/bin` ahead of the existing PATH. Keep `NPM_CONFIG_PREFIX`, but append the npm global bin directory to PATH instead of prepending it, so Home Manager/Nix profile ordering remains authoritative.

**Tech Stack:** home-manager, nix-darwin, zsh, bash

---

### Task 1: Change PATH injection order

**Files:**
- Modify: `user/darwin/profiles/shell.nix`
- Verify: generated shell init files and command resolution

**Step 1: Inspect current shell profile fragment**
- Confirm which lines prepend Homebrew/system paths ahead of Nix-managed paths.

**Step 2: Write the minimal implementation**
- Keep `NPM_CONFIG_PREFIX`.
- Replace PATH prepending with an append-only update for `${HOME}/.local/npm/bin`.
- Do not prepend `/opt/homebrew/bin` or `/usr/local/bin`.

**Step 3: Verify shell command resolution**
- Rebuild or evaluate enough to regenerate shell init files.
- Check `command -v node npm git jq` inside the repo shell / login shell.

**Step 4: Verify fallback tools still remain reachable when needed**
- Confirm `/opt/homebrew/bin` and `/usr/local/bin` are still present later in PATH if inherited by the system environment.
