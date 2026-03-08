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
