# Phase C Architecture Design

**Date:** 2026-03-10

## Goal

Complete the architecture cutover started in Phase A+B:

- remove temporary compatibility shims as soon as the live graph no longer depends on them
- fully retire `vars/`
- split OpenClaw into clear ownership boundaries
- keep secrets outside the Nix store
- remove suspicious runtime-local artifacts from the authoritative repo surface

## Decision Summary

Phase C should be a clean architectural cutover, not another mixed cleanup pass.

- `infra/` becomes the only shared infrastructure surface.
- `modules/` becomes the only long-term module tree.
- `profiles/` remains the top-level composition layer for host and user assembly.
- compatibility shims are temporary migration scaffolding and should be removed, not preserved.

## Target OpenClaw Boundaries

OpenClaw should end in five explicit ownership layers:

1. `package`
   - owns the pinned `nix-openclaw` package selection and any package-level patching
   - produces the runnable gateway and CLI package outputs

2. `runtime`
   - owns launchd wiring, wrapper entrypoints, PATH/NODE_PATH shaping, runtime probes, and runtime
     hygiene
   - may read secrets from local files or environment at execution time
   - must not become the canonical source of persistent config

3. `config`
   - owns declarative `openclaw.json` generation and stable assistant/channel/tool policy
   - should describe what OpenClaw is supposed to do, not how launchd starts it

4. `plugins`
   - owns plugin acquisition, packaging, enablement, and compatibility glue
   - should separate plugin packaging from plugin enablement in config

5. `secrets`
   - owns only runtime secret loading contracts
   - secret values stay in `~/.secrets` or equivalent local secret material and never enter the Nix
     store

Recommended target path:

```text
modules/home/darwin/services/openclaw/
  default.nix
  package.nix
  runtime.nix
  config.nix
  plugins.nix
  secrets.nix
```

## Compatibility Shim Removal Order

Remove shims only after all live imports point at canonical Phase C locations.

### Wave 1: retire `vars/` forwarding

Remove first once every consumer imports `infra/*` directly:

- `vars/networking/default.nix`
- `vars/networking/dns.nix`
- `vars/networking/hosts.nix`
- `vars/networking/mihomo.nix`
- `vars/networking/proxy.nix`
- `vars/networking/ssh.nix`
- `vars/toolchains.nix`
- `vars/default.nix`

This should be the first shim family removed because the desired end-state is unambiguous and the
outputs already treat `infra/` as canonical.

### Wave 2: retire user-level forwarding entrypoints

Remove after `modules/home/*` imports only canonical module files:

- `user/common/core/shells/default.nix`
- `user/common/core/default.nix`
- `user/darwin/profiles/shell.nix`
- `user/darwin/services/default.nix`
- `user/darwin/default.nix`

### Wave 3: retire system-level forwarding entrypoints

Remove last, after host and output composition no longer rely on legacy paths:

- `system/common/default.nix`
- `system/darwin/default.nix`

## `vars/` End-State

`vars/` should be fully retired in Phase C.

Recommendation:

- move any still-useful data into `infra/`
- update all imports to `infra/*`
- delete `vars/README.md` and the entire `vars/` tree once nothing imports it

`vars/` should not remain as a public compatibility surface. Keeping both `infra/` and `vars/` would
extend ambiguity and preserve configuration debt.

## Final OpenClaw Ownership Split

The final ownership model should be:

- package selection and source patching: `package.nix`
- launchd process model, wrapper execution, PATH/NODE_PATH, runtime hygiene: `runtime.nix`
- generated `openclaw.json`, assistants, tools, channels, steady-state defaults: `config.nix`
- plugin derivations, install layout, plugin enablement glue: `plugins.nix`
- local secret file contracts and env injection only: `secrets.nix`

Rules:

- package logic must not also own channel policy
- runtime logic must not also generate stable assistant config
- plugin installation must not be hidden inside unrelated activation hooks if it can be packaged
- secrets must stay outside the store and be injected only at runtime

## `.tmp-openclaw-local/` Policy

`.tmp-openclaw-local/` should be treated as suspicious and non-authoritative.

Status after Phase C: remove it from the tracked declarative tree and keep it out of normal repo
management unless a specific reproducible workflow requires it again.

Recommendation:

- do not keep it as a managed repo surface by default
- if it is still needed for local experiments, move it to an ignored local path outside the tracked
  declarative tree
- exclude it from repo-wide formatting and checks if it remains temporarily

The default assumption for Phase C should be removal from authoritative repo management unless a
specific reproducible test or packaging workflow still requires it.

## Documentation Policy

Phase C should update docs immediately, but narrowly.

Update in Phase C:

- canonical path references
- operator-facing OpenClaw ownership model
- the statement that `infra/` replaces `vars/`
- any deployment instructions invalidated by shim removal

Defer to a follow-up:

- broad prose cleanup
- historical design-doc pruning
- unrelated README consolidation

This keeps Phase C self-consistent without turning it into a general documentation rewrite.

## Recommended Git Strategy

Commit Phase A+B first, then do Phase C as a dedicated commit sequence.

Recommended sequence:

1. commit the current Phase A+B restructuring and formatting baseline
2. create one Phase C branch or linear commit series focused only on shim retirement and module
   cutover
3. keep OpenClaw boundary work in its own commit if the diff is large
4. keep doc updates in a final small commit unless they are tightly coupled to a code move

This matches the desired review shape:

- Phase A+B establishes the stable interim architecture
- Phase C becomes a clean, auditable structural cutover
- rollback remains simpler because the shimmed baseline is preserved in prior history

## Recommended Phase C Execution Order

1. Move remaining consumers from `vars/*` to `infra/*`.
2. Create final canonical OpenClaw submodules under `modules/home/darwin/services/openclaw/`.
3. Update `modules/home/*` and `modules/system/*` to import canonical module files only.
4. Remove `vars/` shims and then delete `vars/`.
5. Remove user-facing compatibility shims.
6. Remove system-facing compatibility shims.
7. Remove or fully exclude `.tmp-openclaw-local/`.
8. Apply the narrow doc updates required by the new canonical paths and ownership model.

## Phase C Exit Criteria

- no live imports reference `vars/`
- no live imports reference temporary shim entrypoints
- OpenClaw package, runtime, config, plugins, and secrets are separate modules
- secrets remain outside the Nix store
- `.tmp-openclaw-local/` is either removed or explicitly excluded from repo management
- docs describe the final canonical structure, not the transitional one
