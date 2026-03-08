# Darwin Structure Design

**Date:** 2026-03-07

**Scope:** Improve maintainability of the Darwin-specific Nix module layout by standardizing directory structure and import wiring without changing behavior.

---

## Goal

Unify the Darwin module layout so both `system/darwin/` and `user/darwin/` follow the same explicit-entry pattern. The main change is replacing automatic directory scanning in the Darwin user layer with explicit import manifests.

This work is intentionally structural. It should not change module behavior, option semantics, host wiring, or activation outcomes.

## Current Problems

- `system/darwin/` already exposes a visible module manifest through `.imports.nix`.
- `user/darwin/`, `user/darwin/profiles/`, and `user/darwin/services/` still rely on `mylib.discoverImports`.
- The repository therefore mixes two wiring styles for similar module trees.
- Auto-discovery makes load order implicit and makes it harder to tell which modules are active by inspection.
- The README still documents scanning behavior, which reinforces the inconsistency.

## Chosen Approach

Adopt a single explicit import pattern across the Darwin-specific trees:

- `default.nix` is the entrypoint for the current layer.
- `.imports.nix` is the ordered manifest for modules inside that layer.
- Adding a new module requires editing the corresponding `.imports.nix`.
- Automatic scanning via `mylib.discoverImports` is removed from the Darwin user layer.

This keeps the current information architecture intact while making assembly rules obvious.

## Directory Rules

The existing domain-oriented directory names remain in place:

- `system/darwin/`
- `user/darwin/`
- `user/darwin/apps/`
- `user/darwin/profiles/`
- `user/darwin/services/`

Entrypoint conventions are standardized:

- `default.nix`: layer entrypoint and local initialization only
- `.imports.nix`: ordered list of submodules in the current directory

Single-file modules keep descriptive names such as `ghostty.nix`, `shell.nix`, and `security.nix`.

Multi-file features remain directory-backed modules such as `services/mihomo/` and `services/postgresql/`.

## Import Layout

### `system/darwin/`

- Keep `default.nix` as the top-level Darwin system entry.
- Keep `../common` as an explicit extra import at the top level.
- Keep `.imports.nix` as the ordered manifest for Darwin-specific system modules.

### `user/darwin/`

- `default.nix` should only handle local bootstrap concerns such as `home.homeDirectory`, `xdg.enable`, and explicit imports.
- A new `.imports.nix` should list `ghostty.nix`, `apps/`, `profiles/`, and `services/` in a deliberate order.
- `../common/core` and `../common/home.nix` remain explicit imports at the top level rather than being hidden behind directory scanning.

### `user/darwin/apps/`

- Keep `default.nix` as the directory entrypoint.
- Add `.imports.nix` even if the directory is currently sparse.
- Future application-level modules must be listed there explicitly.

### `user/darwin/profiles/`

- Replace scanning with `default.nix` importing `./.imports.nix`.
- `.imports.nix` becomes the visible manifest for profile modules such as `shell.nix`.

### `user/darwin/services/`

- Replace scanning with `default.nix` importing `./.imports.nix`.
- `.imports.nix` becomes the visible manifest for service modules such as `mihomo/` and `postgresql/`.

## Naming Rules

The naming pass is deliberately conservative:

- Keep existing domain names: `apps`, `profiles`, `services`, `system`
- Keep existing module filenames unless a name is actively misleading
- Use only `default.nix` and `.imports.nix` as entrypoint filenames
- Update documentation to describe explicit manifests instead of auto-discovery

This avoids turning a maintainability cleanup into an architectural rewrite.

## Migration Boundaries

This change includes:

- replacing implicit scanning with explicit manifests
- aligning directory entrypoints across Darwin trees
- documenting the resulting structure

This change does not include:

- reorganizing domains into a new taxonomy
- extracting unrelated helpers
- changing host-specific assembly
- renaming options or behavior
- modifying module logic unless needed for the import transition

## Validation

The refactor is complete when all of the following are true:

- `user/darwin/`, `user/darwin/apps/`, `user/darwin/profiles/`, and `user/darwin/services/` use explicit imports
- `mylib.discoverImports` is no longer used in those Darwin user-layer entrypoints
- Darwin system and Darwin user trees follow the same visible assembly pattern
- `user/darwin/README.md` matches the final structure and no longer references auto-scan behavior
- repository checks and Darwin eval still pass
- existing modules such as Ghostty, shell preferences, Mihomo, and PostgreSQL remain wired in

## Risks

- Some modules may currently depend on discovery order indirectly.
- Sparse directories may appear harmless while silently not being imported if manifests are incomplete.

## Risk Controls

- Preserve the current effective load order during migration.
- Switch one layer at a time and verify evaluation after each structural change.
- Document the exact rule for adding a new module so the pattern stays stable.
