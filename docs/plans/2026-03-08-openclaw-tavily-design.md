# OpenClaw Tavily Plugin Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate `framix-team/openclaw-tavily` declaratively into the existing Home Manager OpenClaw module while keeping Tavily credentials out of the Nix store.

**Architecture:** Pin the plugin to an exact GitHub tarball revision and hash, install it into `~/.openclaw/extensions/openclaw-tavily` during Home Manager activation, expose the plugin explicitly in `plugins.entries.openclaw-tavily`, and inject `TAVILY_API_KEY` only in the gateway runtime bootstrap from `~/.secrets/tavily-api-key`. Preserve Feishu, `memory-lancedb-pro`, JINA, and proxy behavior unchanged.

**Tech Stack:** Nix, Home Manager, nix-openclaw, OpenClaw plugin system, Tavily API

---

## Approved Decisions

- Use GitHub source tarball installation, not npm GitHub spec.
- Pin exact revision `6db474508f44854864d6c47368c84962ef012120` with fixed hash `sha256-GoveVFn+BSbQPFxYz9AZmhvV+hwJe6M+4YF+yc7sH5Q=`.
- Install plugin into `~/.openclaw/extensions/openclaw-tavily`.
- Inject `TAVILY_API_KEY` only at runtime from `~/.secrets/tavily-api-key`.
- Wire only stable, material plugin config: `searchDepth`, `maxResults`, `includeAnswer`, `includeRawContent`, `timeoutSeconds`.
- Explicitly allow tools `tavily_search`, `tavily_extract`, `tavily_crawl`, `tavily_map`, `tavily_research`.
- Leave `cacheTtlMinutes` on plugin defaults.
