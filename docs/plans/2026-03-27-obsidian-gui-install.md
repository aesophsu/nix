# Obsidian GUI Install Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the Obsidian GUI app to the declarative nix-darwin GUI app list and activate it on
host `stella`.

**Architecture:** Reuse the existing `homebrew.casks` declaration in
`modules/system/darwin/apps.nix` rather than introducing a new module or imperative install path.
Activation happens through `darwin-rebuild switch --flake .#stella`, which drives the Homebrew GUI
layer during rebuild.

**Tech Stack:** Nix, nix-darwin, Homebrew casks

---

### Task 1: Declare and activate Obsidian

**Files:**
- Modify: `modules/system/darwin/apps.nix`
- Verify: `docs/plans/2026-03-27-obsidian-gui-install-design.md`

**Step 1: Update the GUI cask list**

Add `"obsidian"` to the existing `homebrew.casks` list in `modules/system/darwin/apps.nix`.

**Step 2: Review the diff**

Run: `git diff -- modules/system/darwin/apps.nix`
Expected: one added cask entry and no unrelated edits

**Step 3: Activate the configuration**

Run: `darwin-rebuild switch --flake .#stella`
Expected: nix-darwin activation completes successfully and processes the declared Homebrew casks

**Step 4: Verify the install**

Run: `/opt/homebrew/bin/brew list --cask obsidian`
Expected: exit code 0 with `obsidian` listed

**Step 5: Verify repository status**

Run: `git status --short`
Expected: only the intended Obsidian files are modified in addition to any pre-existing user
changes
