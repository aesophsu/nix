# Unused Nix Modules Report Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Identify repository `.nix` files and directories that are not referenced by flake evaluation, then validate each candidate in isolation with `nix flake check` before reporting.

**Architecture:** Start from `flake.nix` outputs and trace repository-local imports, including dynamic module discovery helpers such as `lib/module-discovery.nix`. Build a conservative reachable-file graph rooted in flake outputs, compare it against all repository `.nix` files, then verify each candidate by temporarily removing it in an isolated copy and re-running `nix flake check`.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager, ripgrep, shell scripting

---

### Task 1: Map flake entrypoints

**Files:**
- Read: `flake.nix`
- Read: `outputs/default.nix`
- Read: `outputs/darwin/default.nix`
- Read: `outputs/darwin/tests/default.nix`
- Read: `lib/default.nix`
- Read: `lib/module-discovery.nix`
- Read: `lib/macosSystem.nix`

**Step 1:** Confirm which local files are imported directly from `flake.nix` outputs.

**Step 2:** Record dynamic import helpers and their semantics, especially any directory scanning or manifest-based import rules.

### Task 2: Trace reachable repository modules

**Files:**
- Read: `profiles/system/stella.nix`
- Read: `profiles/user/stella.nix`
- Read: `modules/**/*.nix`
- Read: `hosts/**/*.nix`
- Read: `infra/**/*.nix`
- Read: `overlays/**/*.nix`

**Step 1:** Walk every repository-local import path reachable from the flake entrypoints.

**Step 2:** Expand dynamic imports from `discoverImports`, `.imports.nix`, and default-directory imports.

**Step 3:** Save the final reachable `.nix` set and import edges for comparison.

### Task 3: Compare against repository inventory

**Files:**
- Read: repository-wide `*.nix`
- Read: docs and comments that mention candidate files

**Step 1:** Inventory all repository `.nix` files.

**Step 2:** Subtract the reachable set to find candidate unused files.

**Step 3:** Group candidates by directory and inspect whether entire directories are unused or only partially unused.

**Step 4:** Check whether candidates are referenced only by documentation or comments.

### Task 4: Validate each candidate in isolation

**Files:**
- Temporary isolated copy outside the working tree

**Step 1:** Create an isolated copy of the repository for destructive verification.

**Step 2:** For each candidate file or fully unused directory, temporarily remove it from the isolated copy.

**Step 3:** Run `nix flake check` after each removal and record whether evaluation still succeeds.

**Step 4:** Restore or recreate a clean isolated copy for the next validation as needed.

### Task 5: Write the report

**Files:**
- Create: report content in final response

**Step 1:** Report unused `.nix` files, directories containing only unused modules, experimental or abandoned files, and doc/comment-only references.

**Step 2:** Classify each candidate as `safe to delete`, `likely stale`, or `uncertain (needs manual confirmation)`.

**Step 3:** Include validation evidence from the isolated `nix flake check` runs.
