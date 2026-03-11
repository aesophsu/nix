# Zotero GUI Install Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan
> task-by-task.

**Goal:** Add Zotero to the declarative macOS GUI app set and install it on this machine.

**Architecture:** Modify the existing Homebrew cask list in `modules/system/darwin/apps.nix`, then
run a Darwin rebuild so nix-darwin applies the Homebrew change. Verify both the declaration and the
local Homebrew installation after activation.

**Tech Stack:** Nix, nix-darwin, Homebrew casks

---

### Task 1: Record the approved approach

**Files:**
- Create: `docs/plans/2026-03-11-zotero-gui-install-design.md`
- Create: `docs/plans/2026-03-11-zotero-gui-install.md`

**Step 1: Add the design doc**

Write the short design summary that captures the approved Homebrew cask approach.

**Step 2: Add the implementation plan**

Write the execution steps for the cask change and activation verification.

**Step 3: Verify the docs exist**

Run: `rg -n "Zotero GUI Install" docs/plans/2026-03-11-zotero-gui-install-design.md docs/plans/2026-03-11-zotero-gui-install.md`
Expected: both files match

### Task 2: Add the Zotero cask

**Files:**
- Modify: `modules/system/darwin/apps.nix`

**Step 1: Inspect the current cask list**

Run: `sed -n '1,220p' modules/system/darwin/apps.nix`
Expected: existing GUI casks are declared under `homebrew.casks`

**Step 2: Add the cask**

Change the cask list to include `"zotero"` alongside the existing GUI apps.

**Step 3: Verify the config diff**

Run: `git diff -- modules/system/darwin/apps.nix`
Expected: only the `zotero` cask addition appears

### Task 3: Activate and verify

**Files:**
- Verify: `modules/system/darwin/apps.nix`

**Step 1: Run the Darwin rebuild**

Run: `darwin-rebuild switch --flake .#stella`
Expected: nix-darwin activation completes successfully

**Step 2: Confirm the declaration**

Run: `rg -n '"zotero"' modules/system/darwin/apps.nix`
Expected: one match in the `homebrew.casks` list

**Step 3: Confirm Homebrew recognizes the cask**

Run: `/opt/homebrew/bin/brew list --cask zotero`
Expected: exit code 0 with `zotero` listed
