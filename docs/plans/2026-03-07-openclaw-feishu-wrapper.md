# OpenClaw Feishu Wrapper Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the local `openclaw-local` flake use Feishu declaratively through a Nix wrapper around `clawdbot-feishu`.

**Architecture:** Add a wrapper flake under `openclaw-local/plugins`, point `programs.openclaw.customPlugins` at it, expose the upstream plugin repo as an extension tree, and wire secret files through plugin env vars.

**Tech Stack:** Nix flakes, Home Manager, OpenClaw, Feishu plugin

---

### Task 1: Add the wrapper flake

**Files:**
- Create: `/Users/sue/code/openclaw-local/plugins/clawdbot-feishu-nix/flake.nix`

**Step 1:** Export `openclawPlugin` with Feishu skill directories and required env vars.

**Step 2:** Expose a default package containing the upstream plugin extension tree.

### Task 2: Update the local OpenClaw flake

**Files:**
- Modify: `/Users/sue/code/openclaw-local/flake.nix`

**Step 1:** Add the Feishu wrapper input.

**Step 2:** Remove Telegram channel configuration.

**Step 3:** Add `channels.feishu` in websocket mode.

**Step 4:** Add `programs.openclaw.customPlugins` using the local wrapper.

**Step 5:** Symlink the Feishu extension into `~/.openclaw/extensions/feishu`.

### Task 3: Add secret scaffolding

**Files:**
- Create: `/Users/sue/.secrets/feishu-app-id`
- Create: `/Users/sue/.secrets/feishu-app-secret`

**Step 1:** Create placeholder files with restricted permissions.

**Step 2:** Use those file paths for plugin env resolution.

### Task 4: Activate and verify

**Files:**
- None

**Step 1:** Fill the Feishu secret files with real values.

**Step 2:** Run Home Manager activation for `/Users/sue/code/openclaw-local#sue`.

**Step 3:** Verify the launchd service and extension loading.

**Step 4:** Complete OpenAI Codex OAuth login interactively.
