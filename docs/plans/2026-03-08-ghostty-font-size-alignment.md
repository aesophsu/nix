# Ghostty Font Size Alignment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Change Ghostty's configured font size to match the current macOS Terminal.app default profile size.

**Architecture:** Keep the existing Ghostty Home Manager module and make one narrow config edit in `user/darwin/ghostty.nix`. Preserve the existing font family and all non-size terminal appearance settings.

**Tech Stack:** Nix, Home Manager, Ghostty, macOS Terminal.app defaults

---

### Task 1: Align Ghostty font size with Terminal.app

**Files:**
- Modify: `user/darwin/ghostty.nix`
- Test: `user/darwin/ghostty.nix`

**Step 1: Write the failing test**

Define the expected behavior change in the file diff itself: `font-size = 15.5` should be replaced by `font-size = 11`.

**Step 2: Run test to verify it fails**

Run: `sed -n '1,120p' user/darwin/ghostty.nix`
Expected: shows `font-size = 15.5`

**Step 3: Write minimal implementation**

Change the Ghostty config block to:

```nix
font-family = SF Mono
font-size = 11
```

Leave all other settings unchanged.

**Step 4: Run test to verify it passes**

Run: `sed -n '1,120p' user/darwin/ghostty.nix`
Expected: shows `font-size = 11`

Run: `nix eval --raw .#darwinConfigurations.stella.config.home-manager.users.sue.xdg.configFile.\"ghostty/config\".text`
Expected: rendered config contains `font-family = SF Mono` and `font-size = 11`

**Step 5: Commit**

```bash
git add user/darwin/ghostty.nix
git commit -m "style: align ghostty font size with terminal"
```
