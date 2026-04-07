# Mihomo Disable Airport1 Keep Airport2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove `Airport1` from the maintained Mihomo configuration and leave `Airport2` as the only active upstream.

**Architecture:** Update both the tracked example config and the local runtime config so only `Airport2Raw` and `Airport2` remain. Remove the `Airport1Bootstrap` dependency and rewrite the README to document that `Airport1` is disabled because the provider no longer supports third-party clients.

**Tech Stack:** Mihomo YAML configuration, Markdown docs

---

### Task 1: Remove Airport1 provider usage

**Files:**
- Modify: `modules/home/darwin/services/mihomo/config.yaml.example`
- Modify: `modules/home/darwin/services/mihomo/config.local.yaml`

**Step 1: Delete `proxy-providers.Airport1`**

Keep only `Airport2Raw` and `Airport2`.

**Step 2: Delete `Airport1Bootstrap` coupling**

Remove `proxy: Airport1Bootstrap` from `Airport2Raw` and remove the bootstrap group.

**Step 3: Collapse groups to `Airport2` only**

Change `Auto`, `AI`, `HK`, `TW`, `JP`, `SG`, `US`, and `GLOBAL` to consume only `Airport2`.

### Task 2: Update README

**Files:**
- Modify: `modules/home/darwin/services/mihomo/README.md`

**Step 1: Replace Airport1 maintenance docs**

Document that `Airport1` is disabled because the upstream now requires its own client.

**Step 2: Remove stale manual update instructions**

Delete the one-time subscription workflow that no longer applies.

### Task 3: Verify configuration

**Files:**
- Verify: `modules/home/darwin/services/mihomo/config.yaml.example`
- Verify: `modules/home/darwin/services/mihomo/config.local.yaml`

**Step 1: Validate YAML**

Run a YAML parser against the edited files.

**Step 2: Validate runtime config**

Run `mihomo -t -d ~/.config/mihomo` to confirm the local runtime configuration still loads.
