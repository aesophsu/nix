# Mihomo Airport1 Manual Snapshot Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Convert `Airport1` from a URL-updated provider into a locally maintained snapshot so one-time subscription links are not embedded in long-lived Mihomo config.

**Architecture:** Keep the existing `airport1.yaml` -> `airport1-controlled.yaml` transform flow, but stop declaring `Airport1Raw` as an `http` provider in the maintained config. `Airport1` remains a file-backed provider that reads the transformed local snapshot, while documentation defines a deliberate manual import/update workflow for future one-time links.

**Tech Stack:** Nix, Home Manager, Mihomo YAML provider configuration, Markdown docs

---

### Task 1: Remove long-lived Airport1 URL provider from maintained config

**Files:**
- Modify: `modules/home/darwin/services/mihomo/config.yaml.example`
- Modify: `modules/home/darwin/services/mihomo/config.local.yaml`

**Step 1: Remove `proxy-providers.Airport1Raw`**

Keep `Airport1` as a `file` provider backed by `./proxies/airport1-controlled.yaml`.

**Step 2: Preserve the transform-based runtime path**

Do not change the raw snapshot path `./proxies/airport1.yaml`; manual imports still refresh that file and the existing transform logic continues to produce `airport1-controlled.yaml`.

### Task 2: Document the manual Airport1 maintenance workflow

**Files:**
- Modify: `modules/home/darwin/services/mihomo/README.md`

**Step 1: Explain the new maintenance model**

State clearly that `Airport1` is a local snapshot, not a normal auto-updating subscription.

**Step 2: Document the safe manual update procedure**

Describe how to consume a fresh one-time link exactly once into `~/.config/mihomo/proxies/airport1.yaml`, regenerate the controlled provider, and restart `mihomo`.

### Task 3: Verify config consistency

**Files:**
- Verify: `modules/home/darwin/services/mihomo/config.yaml.example`
- Verify: `modules/home/darwin/services/mihomo/config.local.yaml`
- Verify: `modules/home/darwin/services/mihomo/README.md`

**Step 1: Validate YAML shape**

Run a YAML parser against the example and local config to ensure the edited provider sections remain valid.

**Step 2: Re-scan Airport1 references**

Check that maintained config no longer treats `Airport1` as an `http` provider, while docs still mention the local snapshot path and transform flow.
