# OpenClaw Nix-First Design

**Date:** 2026-03-07

## Goal

Define a stable operating model for using OpenClaw with a Nix-managed system:

- Nix remains the source of truth for persistent state
- OpenClaw CLI remains available for diagnosis and verification
- assistant guidance can use the OpenClaw skill without drifting into imperative system management

## Context

- The repository already uses Nix as the primary system-management layer.
- An OpenClaw skill is installed locally and provides operational knowledge for OpenClaw installation, configuration, troubleshooting, and maintenance.
- The user wants both the reproducibility of Nix and the convenience of skill-driven OpenClaw expertise.

The main design problem is not capability overlap. It is preventing configuration drift between declarative Nix state and ad hoc OpenClaw runtime changes.

## Chosen Approach

Adopt a strict `Nix-first` model:

- persistent installation and configuration changes are made in Nix
- OpenClaw commands are primarily used for read-only inspection, health checks, and post-change verification
- imperative OpenClaw changes are treated as exceptions, not normal workflow

This keeps rollback, review, migration, and recovery aligned with the rest of the repository.

## Operating Rules

### 1. Source Of Truth

Nix configuration is the canonical source for:

- package installation
- version selection
- service definitions
- environment variables and secrets wiring
- long-lived OpenClaw configuration
- plugin enablement that affects the steady-state system

If Nix and runtime state disagree, Nix wins.

### 2. Allowed Direct OpenClaw Usage

The assistant may directly run OpenClaw commands for:

- status checks
- logs and diagnostics
- health probes
- validation after a Nix change
- temporary local inspection that does not create persistent drift

Examples:

- `openclaw status`
- `openclaw gateway status`
- `openclaw doctor`
- `openclaw channels status --probe`
- `openclaw logs --follow`

### 3. Disallowed By Default

The assistant should not directly perform persistent OpenClaw mutations unless the user explicitly requests an exception.

Disallowed-by-default examples:

- `openclaw update`
- interactive `openclaw configure`
- persistent `openclaw config set`
- direct edits to runtime-owned OpenClaw config files as the primary path
- any workflow that upgrades or reconfigures OpenClaw outside Nix and leaves it that way

### 4. Exception Handling

If an imperative OpenClaw change is temporarily required for debugging or discovery:

- the change must be identified as a temporary deviation
- the reason for the deviation must be stated
- the corresponding Nix representation must be proposed before the task is considered complete

Temporary drift is acceptable only when it is deliberate, visible, and scheduled to be reconciled.

## Assistant Behavior

When handling OpenClaw tasks in this repository, the assistant should follow this decision order:

1. Determine whether the request changes long-lived system state.
2. If yes, implement through Nix or propose the Nix change first.
3. If no, use OpenClaw CLI for inspection or verification as needed.
4. Use the OpenClaw skill for domain knowledge, but do not treat its imperative examples as the default execution path in this repository.

## Task Categories

### Directly Allowed

- inspect current OpenClaw status
- read logs
- run doctor and health checks
- verify channel connectivity
- confirm whether a Nix-applied change took effect

### Must Go Through Nix

- install or remove OpenClaw
- change package version
- define or alter services
- change persistent config defaults
- add stable channel configuration
- wire model providers for long-term use
- enable plugins or integrations intended to persist

### Require Explicit User Exception

- emergency hotfixes performed directly with OpenClaw CLI
- one-off runtime experiments that intentionally bypass Nix
- temporary commands that mutate persistent state before the Nix representation exists

## Risks

- Some OpenClaw documentation and skill guidance naturally assumes an imperative workflow.
- Fast debugging can tempt direct runtime edits that never get reconciled.
- Users may mistake successful runtime experiments for completed system configuration.

## Risk Controls

- treat Nix as the required landing zone for any persistent change
- explicitly label temporary drift when it is introduced
- use OpenClaw CLI as evidence-gathering tooling, not as the default configuration engine
- validate final behavior after Nix changes with OpenClaw status and health commands

## Success Criteria

- OpenClaw changes remain reviewable and reproducible through Nix
- the assistant can still diagnose and operate OpenClaw effectively using the installed skill
- runtime drift is minimized and never left implicit
- the user can rely on one clear rule: persistent state belongs in Nix

## Current Working Architecture

The current steady-state OpenClaw setup in this repository is:

- **Entry channel:** Feishu
- **Primary model runtime:** Codex via `openai-codex/gpt-5.2-codex`
- **Persistent memory plugin:** `memory-lancedb-pro`
- **Web research plugin:** `openclaw-tavily`
- **Built-in web fetch fallback:** Firecrawl via runtime-only `FIRECRAWL_API_KEY`
- **Ownership:** Nix/Home Manager manages the service, config, plugin installs, and long-lived wiring
- **Secrets:** injected at runtime from `~/.secrets`, not stored in Nix

Operationally:

- Feishu is the user-facing entry point into the `main` assistant
- the gateway service is managed declaratively through Nix/Home Manager
- proxy environment is injected into the gateway runtime by the launchd wrapper
- `JINA_API_KEY`, `TAVILY_API_KEY`, `FIRECRAWL_API_KEY`, and Feishu secrets are exported only at runtime from local secret files

## Current Tool Exposure Model

The working tool policy is:

- `tools.profile = "coding"`
- `tools.alsoAllow = [ "group:web" "tavily_search" "tavily_extract" "tavily_crawl" "tavily_map" "tavily_research" ]`
- `tools.deny = [ "group:runtime" ]`
- `tools.fs.workspaceOnly = true`

This is intentionally narrow:

- filesystem tools remain available for coding workflows
- Tavily and built-in web tools are added explicitly
- host runtime tools remain intentionally unavailable
- filesystem access remains constrained to the OpenClaw workspace

### Why `tools.alsoAllow` Was Required

`tools.profile = "coding"` is a restrictive core-tool allowlist. OpenClaw applies tool policy as an intersection pipeline, so `tools.allow` is not an additive escape hatch for plugin tools after the profile has already filtered them out.

The stable working pattern is:

- keep the restrictive profile
- use `tools.alsoAllow` for extra plugin or non-profile tools
- avoid mixing `tools.allow` and `tools.alsoAllow` in the same scope

In practice, `tools.allow` did not expose Tavily tools, while `tools.alsoAllow` did once the gateway restarted on the new config.

## Current Web Stack Responsibilities

The current web stack is split by responsibility:

- **Tavily** is used through explicit plugin tools:
  - `tavily_search`
  - `tavily_extract`
  - `tavily_crawl`
  - `tavily_map`
  - `tavily_research`
- **Firecrawl** is used internally by the built-in `web_fetch` tool when `FIRECRAWL_API_KEY` is present in the gateway runtime

In this OpenClaw build, Firecrawl is **runtime-env-only**:

- runtime code supports Firecrawl fallback
- the config validator rejects `tools.web.fetch.firecrawl`
- therefore declarative Firecrawl config in `openclaw.json` is not currently valid for this build

The stable working pattern today is:

- expose `group:web` via `tools.alsoAllow`
- inject `FIRECRAWL_API_KEY` at runtime only
- let `web_fetch` use Firecrawl automatically when its internal fallback path is triggered

## Current Memory Design

The current memory layer uses `memory-lancedb-pro` with Jina-backed retrieval:

- embeddings provider: OpenAI-compatible Jina embeddings
- reranker provider: Jina reranker
- storage path: `~/.openclaw/memory/lancedb-pro`
- slot binding: `plugins.slots.memory = "memory-lancedb-pro"`

The scoped memory model is conservative:

- default scope: `project:openclaw-nix`
- explicit scope definitions for `global`, `project:*`, and `agent:*`
- `main` currently receives `global` and `project:openclaw-nix`

The current rollout is intentionally conservative:

- `autoCapture = false`
- `autoRecall = false`
- `enableManagementTools = false`

## Current Tavily Design

The Tavily integration is intentionally reproducible and secret-safe:

- plugin id: `openclaw-tavily`
- source: GitHub tarball
- pinned revision: `6db474508f44854864d6c47368c84962ef012120`
- install path: `~/.openclaw/extensions/openclaw-tavily`
- API key source: `~/.secrets/tavily-api-key`

The API key is not written into generated Nix config and is not stored in the Nix store. It is injected only into the gateway runtime environment.

The currently exposed Tavily tools are:

- `tavily_search`
- `tavily_extract`
- `tavily_crawl`
- `tavily_map`
- `tavily_research`

## Current Firecrawl Design

The Firecrawl integration is intentionally minimal in this build:

- no standalone plugin
- no Firecrawl config stored in generated OpenClaw config
- `FIRECRAWL_API_KEY` injected only at runtime from `~/.secrets/firecrawl-api-key`

This is required because the current build rejects declarative `tools.web.fetch.firecrawl` config even though the runtime contains Firecrawl support code.

## Current Security Boundary

The current boundary is intentionally useful but not fully hardened:

- Feishu-facing assistant can use filesystem tools and web/Tavily tools
- host runtime tools are intentionally denied via `group:runtime`
- filesystem tools are workspace-scoped via `tools.fs.workspaceOnly = true`
- `agents.defaults.sandbox.mode = "off"` currently leaves execution unsandboxed if runtime tools are ever re-enabled

This means the main practical safety boundary today is:

- no host exec/runtime tools
- workspace-scoped filesystem access
- explicit web/Tavily exposure only

## Safe Modification Checklist

When modifying this OpenClaw setup later:

1. **Plugin installation**
   - keep persistent plugin installs declarative in Nix/Home Manager
   - pin external plugin sources by exact revision and hash
   - install into `~/.openclaw/extensions/...` through declarative activation steps

2. **Tool exposure**
   - preserve `tools.profile = "coding"` unless broadening access is deliberate
   - use `tools.alsoAllow` for plugin tools
   - do not assume `tools.allow` is additive under a restrictive profile
   - keep `tools.deny = [ "group:runtime" ]` unless host execution is intentionally being reopened

3. **Secrets**
   - keep API keys out of Nix expressions and generated config
   - inject secrets only at runtime from `~/.secrets/...`
   - treat any secret value appearing in the Nix store as a regression

4. **Schema/runtime mismatches**
   - if runtime code appears to support a field but `openclaw config validate` rejects it, prefer the validator
   - treat that as a build-specific schema mismatch, not as permission to force unsupported config into `openclaw.json`
   - for this build, Firecrawl support is runtime-env-only rather than declarative

5. **Gateway lifecycle**
   - after tool-policy or runtime-wrapper changes, verify the running gateway actually restarted
   - do not assume a rebuild alone is sufficient; confirm with `openclaw gateway status`
   - re-run post-change verification against the live gateway, not just static config
