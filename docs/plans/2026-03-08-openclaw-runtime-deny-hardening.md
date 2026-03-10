# OpenClaw Runtime Deny Hardening Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove host runtime command execution from the Feishu-facing assistant while preserving filesystem and web tools.

**Architecture:** Keep the existing `coding` profile and explicit `group:web` allow entry, then add a single `tools.deny = [ "group:runtime" ]` override in the declarative OpenClaw Home Manager module. This leaves the current Feishu, Codex, memory-lancedb-pro, and proxy wiring unchanged while blocking `exec`, `bash`, and `process` from the assistant tool surface.

**Tech Stack:** Nix, nix-darwin, Home Manager, OpenClaw

---

### Task 1: Apply the minimal tool policy override

**Files:**
- Modify: `user/darwin/services/openclaw/default.nix`

**Step 1: Add the runtime deny override**

Set:

```nix
tools = {
  profile = "coding";
  allow = [ "group:web" ];
  deny = [ "group:runtime" ];
  fs.workspaceOnly = true;
};
```

**Step 2: Rebuild and activate**

Run: `XDG_CACHE_HOME=/tmp sudo darwin-rebuild switch --flake .`
Expected: successful nix-darwin and Home Manager activation

**Step 3: Reload the gateway if the running process still reflects stale tool policy**

Run: `openclaw gateway restart`
Expected: LaunchAgent restarts and the gateway reloads `~/.openclaw/openclaw.json`

### Task 2: Verify the live runtime

**Files:**
- Inspect: `~/.openclaw/openclaw.json`
- Inspect: `/tmp/openclaw/openclaw-gateway.log`

**Step 1: Verify status and diagnostics**

Run:
- `openclaw status`
- `openclaw doctor`
- `openclaw security audit`

Expected:
- gateway reachable
- Feishu configured
- no new config errors

**Step 2: Verify Feishu filesystem round-trip**

Run a Feishu-targeted agent turn that reads the workspace path or a workspace file.
Expected: successful outbound reply and gateway log evidence of delivery

**Step 3: Verify Feishu web round-trip**

Run a Feishu-targeted agent turn that uses `web_search` or `web_fetch`.
Expected: successful outbound reply and no runtime tool denial for `group:web`

**Step 4: Verify host runtime tools are blocked**

Run an agent turn asking for `pwd` via shell/exec.
Expected: assistant cannot call `exec`/`bash` and either refuses or reports the tool is unavailable
