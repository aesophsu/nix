# Repository Guidance

This repository uses Nix as the source of truth for persistent system state.

## OpenClaw Rules

When working on OpenClaw in this repository:

- treat Nix configuration as authoritative for persistent installation, versioning, services, environment wiring, and long-lived OpenClaw configuration
- use the OpenClaw CLI primarily for diagnosis, inspection, probes, logs, and verification after Nix changes
- do not use imperative OpenClaw changes as the default path for persistent system changes

If Nix state and runtime OpenClaw state disagree, prefer Nix and reconcile runtime state back to the Nix definition.

### Allowed Direct OpenClaw Actions

- `openclaw status`
- `openclaw gateway status`
- `openclaw doctor`
- `openclaw channels status --probe`
- `openclaw logs --follow`
- other read-only inspection and validation commands that do not create persistent drift

### Must Go Through Nix

- installing or removing OpenClaw
- changing OpenClaw versions
- defining or altering services
- changing persistent defaults or stable channel configuration
- wiring model providers or plugins intended for long-term use
- any other change that should survive rebuilds, migration, rollback, or machine replacement

### Require Explicit User Exception

- `openclaw update`
- interactive `openclaw configure`
- persistent `openclaw config set`
- direct edits to runtime-owned OpenClaw configuration as the primary path
- emergency or experimental runtime mutations that intentionally bypass Nix

If an exception is used for debugging or discovery, label it as temporary drift and propose the corresponding Nix representation before considering the work complete.

## Reference

Rationale and design notes live in `docs/plans/2026-03-07-openclaw-nix-first-design.md`.
