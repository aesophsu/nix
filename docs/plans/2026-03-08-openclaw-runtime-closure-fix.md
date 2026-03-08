# OpenClaw Runtime Closure Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the packaged OpenClaw CLI/runtime so `openclaw` resolves on PATH and its basic status commands run without `ERR_MODULE_NOT_FOUND`.

**Architecture:** Patch the local OpenClaw flake with a narrow `overrideAttrs` on the `openclaw-gateway` package. Keep the fix at install time, alongside existing pnpm dependency-layout repairs, and then rebuild only the local Home Manager activation package that owns the OpenClaw profile.

**Tech Stack:** Nix flakes, Home Manager, nix-openclaw overlay, pnpm-based Node packaging

---

### Task 1: Capture the exact failing condition

**Files:**
- Create: `docs/plans/2026-03-08-openclaw-runtime-closure-fix.md`

**Step 1: Reproduce the failure from the realized store path**

Run: `node -e "import('/nix/store/3pwmydpbcp0vv93gb3wmrpshm09jbmhl-openclaw-gateway-unstable-e8f419c4/lib/openclaw/node_modules/.pnpm/@whiskeysockets+baileys@7.0.0-rc.9_audio-decode@2.2.3_sharp@0.34.5/node_modules/@whiskeysockets/baileys/lib/Socket/messages-recv.js').catch(err=>{console.error(err);process.exit(1)})"`
Expected: fail with `ERR_MODULE_NOT_FOUND` for package `long`

**Step 2: Confirm root cause**

Run: `ls -l /nix/store/3pwmydpbcp0vv93gb3wmrpshm09jbmhl-openclaw-gateway-unstable-e8f419c4/lib/openclaw/node_modules/.pnpm/@whiskeysockets+baileys@7.0.0-rc.9_audio-decode@2.2.3_sharp@0.34.5/node_modules/@whiskeysockets/baileys/node_modules`
Expected: empty directory

**Step 3: Confirm package-level patch point already exists**

Run: `sed -n '1,260p' /nix/store/gyiw011xp624fr8kw7dz2xsz2qk3cg6a-gateway-install.sh`
Expected: existing install-time symlink workarounds for undeclared runtime deps

### Task 2: Patch the responsible package definition

**Files:**
- Modify: `.tmp-openclaw-local/flake.nix`

**Step 1: Add an overlay override for `openclaw-gateway`**

Patch the local flake’s `pkgs` import to append a local overlay after `nix-openclaw.overlays.default`.

**Step 2: Extend `installPhase` minimally**

Append shell that:
- finds `long` in `node_modules/.pnpm`
- finds packaged `@whiskeysockets/baileys`
- creates `baileys/node_modules/long` symlink if missing
- optionally creates top-level `node_modules/long` symlink if missing

**Step 3: Keep scope narrow**

Do not change unrelated package versions, lock files, or OpenClaw config behavior.

### Task 3: Rebuild only the OpenClaw Home Manager profile

**Files:**
- Modify: `.tmp-openclaw-local/flake.nix`

**Step 1: Build the local activation package**

Run: `XDG_CACHE_HOME=/tmp GOPROXY=https://goproxy.cn,direct nix build --impure ./.tmp-openclaw-local#homeConfigurations.sue.activationPackage --print-out-paths -L --show-trace`
Expected: exit 0 and print a `home-manager-generation` path

**Step 2: Activate that generation**

Run: `<result-path>/activate`
Expected: exit 0

### Task 4: Verify PATH and runtime health

**Files:**
- Modify: `.tmp-openclaw-local/flake.nix`

**Step 1: Verify PATH**

Run: `command -v openclaw`
Expected: prints a path

**Step 2: Verify CLI runtime**

Run: `openclaw status`
Expected: command runs without `ERR_MODULE_NOT_FOUND`

**Step 3: Verify gateway CLI runtime**

Run: `openclaw gateway status`
Expected: command runs without `ERR_MODULE_NOT_FOUND`
