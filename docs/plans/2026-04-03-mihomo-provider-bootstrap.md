# Mihomo Provider Bootstrap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `Airport2` subscription updates more reliable by downloading its provider content through an `Airport1`-only bootstrap proxy group.

**Architecture:** Keep the existing Nix-first Mihomo layout. Add a hidden bootstrap proxy group that only uses `Airport1`, then point `Airport2`'s provider download path at that group with the provider-level `proxy` field so the subscription fetch no longer depends on unstable direct connectivity or recursive self-use.

**Tech Stack:** Nix, Home Manager, Mihomo YAML provider configuration, launchd

---

### Task 1: Add bootstrap group and provider proxy

**Files:**
- Modify: `modules/home/darwin/services/mihomo/config.local.yaml`
- Modify: `modules/home/darwin/services/mihomo/config.yaml`
- Modify: `modules/home/darwin/services/mihomo/config.yaml.example`

**Step 1: Add an `Airport1Bootstrap` hidden `url-test` group**

Use only `Airport1` nodes and filter to stable non-HK regions already present in the config.

**Step 2: Point `Airport2` provider downloads at that group**

Add `proxy: Airport1Bootstrap` under `proxy-providers.Airport2`.

**Step 3: Rebuild and reload**

Run: `XDG_CACHE_HOME=/tmp sudo darwin-rebuild switch --flake .`

Run: `launchctl kickstart -k gui/$(id -u)/mihomo`

**Step 4: Verify provider refresh**

Run: `curl -s -X PUT http://127.0.0.1:9090/providers/proxies/Airport2`

Expected: no immediate transport error, or at least the request path uses the bootstrap group instead of direct unstable access.

### Task 2: Re-check Airport1 403 characteristics

**Files:**
- None required unless follow-up mitigation is chosen

**Step 1: Reproduce current response**

Run a direct `curl` against the subscription URL without local proxy env.

**Step 2: Inspect response headers/body**

Confirm whether the service still returns `403`, token rate-limit headers, or a provider-specific error payload.

**Step 3: Summarize root cause**

If the response remains `403 by_token`, treat it as a remote token/account problem rather than a local Mihomo configuration issue.
