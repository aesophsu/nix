# OpenClaw Nix-First Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Codify the approved OpenClaw `Nix-first` operating model in repository guidance so future OpenClaw work defaults to declarative Nix changes and uses the OpenClaw CLI only for diagnosis and verification.

**Architecture:** Add a repository-level `AGENTS.md` because this repo currently has no local agent guidance file. Keep the document narrow: define the OpenClaw source-of-truth rule, list what is directly allowed, what must go through Nix, and what requires an explicit user exception. Link the rule set back to the design document for rationale.

**Tech Stack:** Markdown, repository agent instructions, OpenClaw operational workflow, Nix-managed configuration

---

### Task 1: Confirm the repository guidance entry point

**Files:**
- Verify: `AGENTS.md`
- Verify: `docs/plans/2026-03-07-openclaw-nix-first-design.md`

**Step 1: Check whether a repository-level `AGENTS.md` already exists**

Run: `ls -la /Users/sue/nix`
Expected: no `AGENTS.md` is present, so a new repository-level guidance file is needed.

**Step 2: Re-read the approved design**

Run: `sed -n '1,220p' docs/plans/2026-03-07-openclaw-nix-first-design.md`
Expected: confirms the final approved operating model and task boundaries.

### Task 2: Add repository-level OpenClaw collaboration rules

**Files:**
- Create: `AGENTS.md`

**Step 1: Write the guidance skeleton**

Create sections for:

- scope
- default operating rule
- directly allowed OpenClaw actions
- actions that must go through Nix
- explicit-exception actions

**Step 2: Encode the core rule**

State plainly that:

- Nix is the source of truth for persistent OpenClaw state
- OpenClaw CLI is for diagnosis, inspection, and verification by default
- imperative persistent changes are not the default path in this repository

**Step 3: Add a concise reference back to the design doc**

Include a short note that the rationale lives in:

```text
docs/plans/2026-03-07-openclaw-nix-first-design.md
```

### Task 3: Verify the guidance before completion

**Files:**
- Verify: `AGENTS.md`
- Verify: `docs/plans/2026-03-07-openclaw-nix-first.md`

**Step 1: Read the final `AGENTS.md`**

Run: `sed -n '1,220p' AGENTS.md`
Expected: clearly states the OpenClaw `Nix-first` boundary and contains no conflicting imperative guidance.

**Step 2: Confirm the plan file exists**

Run: `sed -n '1,220p' docs/plans/2026-03-07-openclaw-nix-first.md`
Expected: shows the implementation plan header and tasks.

**Step 3: Check git status**

Run: `git status --short`
Expected: shows the new `AGENTS.md` and plan/design docs as expected.

---

## Current Operating Notes

The plan above established the repository rule. The current working OpenClaw state built on top of that rule is:

- Nix/Home Manager owns the persistent OpenClaw config, service wiring, plugin installs, and runtime wrapper
- Feishu is the current user-facing entry path into the `main` assistant
- Codex is the current model runtime through `openai-codex/gpt-5.2-codex`
- `memory-lancedb-pro` is the active memory slot with Jina embeddings and reranking
- `openclaw-tavily` is the active Tavily web research plugin
- Firecrawl is active only as runtime-backed support for built-in `web_fetch`
- proxy settings plus `JINA_API_KEY`, `TAVILY_API_KEY`, `FIRECRAWL_API_KEY`, and Feishu secrets are injected only at gateway runtime from local files under `~/.secrets`

### Current Tool Policy

The current working policy is:

- `tools.profile = "coding"`
- `tools.alsoAllow = [ "group:web" "tavily_search" "tavily_extract" "tavily_crawl" "tavily_map" "tavily_research" ]`
- `tools.deny = [ "group:runtime" ]`
- `tools.fs.workspaceOnly = true`

Why this matters:

- the coding profile keeps the base tool surface narrow
- Tavily is exposed additively through `tools.alsoAllow`
- built-in web tools stay available through `group:web`
- runtime execution stays unavailable
- filesystem access stays workspace-scoped

### Why `tools.allow` Was Not The Right Mechanism

Under a restrictive `tools.profile`, OpenClaw applies tool filtering as an intersection pipeline. `tools.allow` does not re-add plugin tools after the profile has already removed them. `tools.alsoAllow` is the additive mechanism that works with restrictive profiles.

In the current setup, Tavily exposure only worked reliably after:

- moving Tavily tool names into `tools.alsoAllow`
- removing conflicting `tools.allow` usage in the same scope
- restarting the gateway so the live process picked up the new policy

### Current Plugin Notes

**Memory**

- plugin: `memory-lancedb-pro`
- storage: `~/.openclaw/memory/lancedb-pro`
- embeddings: Jina OpenAI-compatible endpoint
- reranker: Jina rerank API
- rollout posture:
  - `autoCapture = false`
  - `autoRecall = false`
  - `enableManagementTools = false`

**Tavily**

- plugin: `openclaw-tavily`
- pinned source revision: `6db474508f44854864d6c47368c84962ef012120`
- key injection: runtime-only from `~/.secrets/tavily-api-key`
- available tools:
  - `tavily_search`
  - `tavily_extract`
  - `tavily_crawl`
  - `tavily_map`
  - `tavily_research`

**Firecrawl**

- used by built-in `web_fetch`, not as a plugin
- key injection: runtime-only from `~/.secrets/firecrawl-api-key`
- current build behavior:
  - runtime code supports Firecrawl fallback
  - config validator rejects `tools.web.fetch.firecrawl`
  - therefore Firecrawl is runtime-env-only in this build

### Current Web Responsibilities

- Tavily handles explicit search/extract/crawl/research tool calls
- Firecrawl is used internally by `web_fetch` when its fallback path is triggered and `FIRECRAWL_API_KEY` is present

### Current Security Boundary

The current Feishu-facing assistant can use:

- filesystem tools
- web tools
- Tavily tools

It cannot use:

- host runtime/exec tools, because `group:runtime` is denied

Additional constraints:

- filesystem access is limited to the configured workspace
- sandboxing is currently off, so restoring runtime tools later would widen risk materially

### Safe Modification Checklist

- Make persistent plugin changes in Nix/Home Manager, not imperatively
- Pin external plugin sources by exact revision and hash
- Use `tools.alsoAllow` for plugin tool exposure under restrictive profiles
- Keep secrets runtime-only from `~/.secrets`
- If runtime code and config validation disagree, keep config valid and use the smallest supported runtime-only path
- After changing tool policy or gateway wrapper logic, confirm the gateway actually restarted
- Verify against the live gateway and the `main` agent path before calling the change complete

### Next Planned Integration Order

1. Jina Reader
2. LangGraph
3. GPT-Researcher
