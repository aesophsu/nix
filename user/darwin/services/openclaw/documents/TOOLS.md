# TOOLS.md

This file is managed by Nix. A plugin report is appended below.

## Current Operator Notes

This document records the current intended OpenClaw tool surface for this machine.

### Ownership

- Persistent OpenClaw state is owned by Nix/Home Manager
- OpenClaw CLI is used for inspection and verification
- Runtime secret values are loaded from `~/.secrets` by the gateway wrapper, not committed into generated config

### Current Runtime Architecture

- entry channel: Feishu
- default assistant: `main`
- model runtime: Codex via `openai-codex/gpt-5.2-codex`
- memory plugin: `memory-lancedb-pro`
- Tavily plugin: `openclaw-tavily`
- Firecrawl support: runtime-only fallback inside built-in `web_fetch`
- proxy environment: injected into the gateway runtime wrapper

### Current Tool Policy

- `tools.profile = "coding"`
- `tools.alsoAllow = [ "group:web" "tavily_search" "tavily_extract" "tavily_crawl" "tavily_map" "tavily_research" ]`
- `tools.deny = [ "group:runtime" ]`
- `tools.fs.workspaceOnly = true`

### Why Plugin Tools Use `tools.alsoAllow`

`tools.profile = "coding"` is restrictive. OpenClaw applies profile filtering before later allowlist stages, so `tools.allow` is not a reliable additive mechanism for plugin tools in this setup.

Use `tools.alsoAllow` when exposing plugin tools while preserving a restrictive profile.

### Tavily

- plugin id: `openclaw-tavily`
- pinned revision: `6db474508f44854864d6c47368c84962ef012120`
- API key source: `~/.secrets/tavily-api-key`
- key injection mode: runtime-only
- available tools:
  - `tavily_search`
  - `tavily_extract`
  - `tavily_crawl`
  - `tavily_map`
  - `tavily_research`

### Firecrawl

- integration mode: built-in `web_fetch` fallback, not a plugin
- API key source: `~/.secrets/firecrawl-api-key`
- key injection mode: runtime-only
- current build limitation:
  - runtime code supports Firecrawl
  - config validator rejects `tools.web.fetch.firecrawl`
  - declarative Firecrawl config is therefore not currently valid in this build

### Current Web Stack Responsibilities

- Tavily handles explicit search/extract/crawl/research tool calls
- Firecrawl is used internally by `web_fetch` when `FIRECRAWL_API_KEY` is present and the fallback path is used

### Memory

- plugin id: `memory-lancedb-pro`
- storage path: `~/.openclaw/memory/lancedb-pro`
- embeddings: Jina OpenAI-compatible embeddings
- rerank: Jina reranker
- rollout posture:
  - `autoCapture = false`
  - `autoRecall = false`
  - `enableManagementTools = false`

### Current Security Boundary

- Feishu-facing assistant can use filesystem plus web/Tavily tools
- host runtime tools are intentionally unavailable
- filesystem tools are workspace-scoped
- sandbox is currently off

### Runtime Secret Inputs

- `JINA_API_KEY`
- `TAVILY_API_KEY`
- `FIRECRAWL_API_KEY`
- Feishu app secrets

All are injected at runtime only and should not be written into Nix expressions or generated config.

### Safe Modification Checklist

- Keep plugin installation declarative in Nix/Home Manager
- Pin external plugin sources by exact revision and hash
- Keep secrets out of the Nix store and inject them only at runtime
- Use `tools.alsoAllow` for plugin tool exposure under restrictive profiles
- If runtime code supports a field but config validation rejects it, keep config valid and use the smallest supported runtime-only path
- Keep `group:runtime` denied unless widening trust is intentional
- After policy or wrapper changes, verify the live gateway restarted before testing
