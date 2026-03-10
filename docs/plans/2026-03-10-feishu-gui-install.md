# Feishu GUI Install Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan
> task-by-task.

**Goal:** Add the mainland China Feishu desktop client to the declarative macOS GUI app set and
activate it on this machine.

**Architecture:** Modify the existing Homebrew cask list in `system/darwin/apps.nix`, then run a
Darwin rebuild so nix-darwin applies the Homebrew change.

**Tech Stack:** Nix, nix-darwin, Homebrew casks

---

### Task 1: Add the Feishu cask

**Files:**

- Modify: `system/darwin/apps.nix`

**Step 1: Inspect the current cask list**

Run: `sed -n '1,220p' system/darwin/apps.nix` Expected: existing GUI casks are declared under
`homebrew.casks`

**Step 2: Add the mainland client**

Change the cask list to include `"feishu"` alongside the existing GUI apps.

**Step 3: Verify the config diff**

Run: `git diff -- system/darwin/apps.nix` Expected: only the `feishu` cask addition appears

### Task 2: Activate and verify

**Files:**

- Verify: `system/darwin/apps.nix`

**Step 1: Run the Darwin rebuild**

Run: `darwin-rebuild switch --flake .#stella` Expected: nix-darwin activation completes successfully

**Step 2: Confirm the declaration**

Run: `rg -n '"feishu"' system/darwin/apps.nix` Expected: one match in the `homebrew.casks` list

**Step 3: Confirm Homebrew recognizes the cask**

Run: `/opt/homebrew/bin/brew list --cask feishu` Expected: exit code 0 with `feishu` listed
