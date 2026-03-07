# Ghostty Apple Font Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Switch Ghostty to an Apple-native terminal font configuration centered on `SF Mono`.

**Architecture:** Update the existing Home Manager Ghostty module in place. Because this is a configuration-only change, verify by inspecting the generated config and evaluating the rendered Home Manager text output rather than adding automated tests.

**Tech Stack:** nix-darwin, Home Manager, Ghostty, macOS fonts

---

### Task 1: Update the Ghostty font configuration

**Files:**
- Modify: `user/darwin/ghostty.nix`

**Step 1: Edit the Ghostty font family**

- Replace `FiraCode Nerd Font Mono` with `SF Mono`.

**Step 2: Remove the Nerd Font fallback**

- Delete the `Symbols Nerd Font Mono` font-family line so the configuration uses only the Apple-native face.

**Step 3: Keep the remaining visual settings unchanged**

- Preserve the current size, theme, padding, opacity, cursor, and macOS options.

### Task 2: Verify the generated config

**Files:**
- Verify: `user/darwin/ghostty.nix`

**Step 1: Inspect the source file**

Run: `sed -n '1,120p' user/darwin/ghostty.nix`

Expected: `font-family = SF Mono` is present and `Symbols Nerd Font Mono` is absent.

**Step 2: Evaluate the rendered Home Manager text**

Run: `nix eval --raw .#darwinConfigurations.stella.config.home-manager.users.sue.xdg.configFile.\"ghostty/config\".text`

Expected: the rendered config contains `font-family = SF Mono` and does not contain the Nerd Font fallback line.
