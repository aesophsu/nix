# Ghostty Darwin Integration Implementation Plan
> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Install Ghostty via Homebrew cask and manage its macOS user configuration from this Nix repo with a font and layout tuned for the MacBook Air M4.

**Architecture:** Keep GUI app installation in `system/darwin/apps.nix`, add a dedicated Home Manager module under `user/darwin/` to generate `~/.config/ghostty/config`, and reuse system-managed fonts already declared in the desktop font module. The Ghostty config will prefer a Nerd Font-backed coding face with restrained visual settings for clarity, battery life, and smooth macOS behavior.

**Tech Stack:** nix-darwin, Home Manager, Homebrew casks, Ghostty, macOS

---

### Task 1: Add Ghostty application installation

**Files:**
- Modify: `system/darwin/apps.nix`

**Step 1: Add `ghostty` to the Homebrew cask list**
- Keep the existing GUI-app policy unchanged.

**Step 2: Verify the cask declaration diff**
- Ensure no unrelated Homebrew policy changes are introduced.

### Task 2: Add Ghostty user configuration module

**Files:**
- Create: `user/darwin/ghostty.nix`
- Verify: `user/darwin/default.nix` import behavior

**Step 1: Define a Home Manager file for `~/.config/ghostty/config`**
- Set Ghostty font family to `FiraCode Nerd Font`.
- Set a size appropriate for a MacBook Air M4 display.
- Configure pragmatic macOS-friendly defaults: padding, scrollback, cursor, shell integration, and restrained visual effects.

**Step 2: Keep the config self-contained and commented only where needed**
- Avoid theme sprawl and unnecessary options.

### Task 3: Verify generated configuration shape

**Files:**
- Verify: `system/common/fonts.nix`, `user/darwin/ghostty.nix`

**Step 1: Evaluate or inspect the rendered Ghostty config target**
- Confirm the file path and key settings are present.

**Step 2: Evaluate Home Manager / Darwin output enough to ensure the new module is wired in**
- Use targeted `nix eval` where possible.
