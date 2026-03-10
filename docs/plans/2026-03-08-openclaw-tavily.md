# OpenClaw Tavily Plugin Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the Tavily OpenClaw plugin declaratively and verify it loads and serves Tavily tools after activation.

**Architecture:** Extend `user/darwin/services/openclaw/default.nix` with a pinned source tarball, activation install step, runtime API key injection, explicit plugin entry config, and explicit tool allow-list additions. Verify with OpenClaw CLI after rebuild.

**Tech Stack:** Nix, Home Manager, OpenClaw CLI, Tavily plugin `framix-team/openclaw-tavily`

---

### Task 1: Add declarative plugin packaging and config

**Files:**
- Modify: `user/darwin/services/openclaw/default.nix`

**Step 1:** Add pinned Tavily source metadata and install descriptor.

**Step 2:** Add `openclaw-tavily` to `plugins.allow`, `plugins.entries`, and `plugins.installs`.

**Step 3:** Add explicit Tavily tools to `tools.allow`.

**Step 4:** Add activation logic to unpack the pinned tarball into `~/.openclaw/extensions/openclaw-tavily` and install runtime dependencies.

**Step 5:** Extend plugin SDK symlink setup to include `openclaw-tavily`.

**Step 6:** Inject `TAVILY_API_KEY` only in the gateway bootstrap from `~/.secrets/tavily-api-key`.

### Task 2: Rebuild and activate

**Files:**
- Verify: `user/darwin/services/openclaw/default.nix`

**Step 1:** Run the Home Manager/Nix rebuild used by this repo.

**Step 2:** Confirm activation finishes without changing unrelated OpenClaw behavior.

### Task 3: Verify plugin behavior

**Files:**
- Verify: `user/darwin/services/openclaw/default.nix`

**Step 1:** Run `openclaw plugins list`.

**Step 2:** Run `openclaw doctor`.

**Step 3:** Run `openclaw status`.

**Step 4:** Confirm `openclaw-tavily` is loaded.

**Step 5:** Run one `tavily_search` test.

**Step 6:** Run one `tavily_extract` test.
