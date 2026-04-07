# OpenClaw Maintenance Baseline

## Current Baseline

- Nix-first installation and service management remain authoritative.
- Runtime target is `OpenClaw 2026.4.5`.
- Merged upgrade baseline is commit `e7a6d7f` on `main`.
- Current OpenClaw flake input state keeps `nix-openclaw` at `0f4d066`.
- Homebrew CLI visibility is now provided declaratively through Home Manager shell PATH exposure to
  `/opt/homebrew/bin`; it no longer depends on manual shell edits.
- Validation baseline:
  - `nix build .#darwinConfigurations.stella.system`
  - `sudo darwin-rebuild switch --flake .#stella`
  - `openclaw --version`
  - `openclaw status`
  - `openclaw doctor`
  - `openclaw gateway status`

## Local Override Scope

[`modules/home/darwin/services/openclaw/package.nix`](/Users/sue/nix/modules/home/darwin/services/openclaw/package.nix) is a temporary compatibility layer. It currently owns only these concerns:

1. Source override to upstream `v2026.4.5` (`3e72c035`) until `nix-openclaw` ships the same or newer release.
2. Packaging compatibility fixes needed for Nix output closure validation.
3. Local runtime adjustments that keep the launchd label, bundled plugin names, and wrapper environment aligned with this repo's Nix-managed deployment.

Anything outside those three categories should not be added there.

Adjacent non-OpenClaw compatibility layers still present after the upgrade:

1. [`overlays/direnv-darwin-cgo-fix.nix`](/Users/sue/nix/overlays/direnv-darwin-cgo-fix.nix) keeps Darwin builds working until upstream `nixpkgs-darwin` removes the broken `CGO_ENABLED=0` + `-linkmode=external` combination for `direnv`.
2. [`outputs/default.nix`](/Users/sue/nix/outputs/default.nix) keeps flake `pre-commit` checks focused on `nixfmt` and `typos`; full-repo `prettier` enforcement is deferred to a dedicated formatting branch.

## Deferred Cleanup Triggers

Only remove temporary compatibility layers when the corresponding trigger is met:

1. Remove [`overlays/direnv-darwin-cgo-fix.nix`](/Users/sue/nix/overlays/direnv-darwin-cgo-fix.nix) only after upstream `nixpkgs-darwin` no longer evaluates `direnv` with the broken `CGO_ENABLED=0` + `-linkmode=external` combination on Darwin.
2. Restore full flake `prettier` coverage in [`outputs/default.nix`](/Users/sue/nix/outputs/default.nix) only after repository-wide formatting drift is handled in a dedicated formatting branch.
3. Reduce [`modules/home/darwin/services/openclaw/package.nix`](/Users/sue/nix/modules/home/darwin/services/openclaw/package.nix) only when `nix-openclaw` picks up the required OpenClaw source version and runtime fixes upstream.
4. Revisit the insecure package allowlist for `openclaw-2026.3.12` only after upstream package metadata stops flagging the overridden OpenClaw package as insecure during evaluation.

## Removal Order

When updating `nix-openclaw`, try to delete local logic in this order:

1. Remove the source override if upstream already packages `2026.4.5` or newer.
2. Remove the `node-which` install fix if upstream no longer emits dangling symlinks for:
   - `cmake-js/node_modules/.bin/node-which`
   - `node-llama-cpp/node_modules/.bin/node-which`
3. Remove local label/plugin-name rewrites only if upstream runtime behavior matches this repo's launch agent and plugin discovery expectations.

Do not keep stale patches "just because they still work". If upstream covers a case, delete the local patch immediately.

## Proxy Policy

Daemon fetch behavior should not be managed through `nix.settings.http-proxy` or `nix.settings.https-proxy`.

- Nix config should keep mirrors, substituters, and general build policy only.
- Temporary daemon proxy changes, when needed, are operational state outside this repository.
- OpenClaw runtime proxy behavior is handled by the Nix-managed wrapper in [`modules/home/darwin/services/openclaw/runtime.nix`](/Users/sue/nix/modules/home/darwin/services/openclaw/runtime.nix).

## Known Non-Blocking Warnings

These do not currently block operation:

- `openclaw gateway status` may still report the LaunchAgent as "out of date or non-standard" even when the service is healthy and running the expected command.
- Node may emit `punycode` deprecation warnings during CLI diagnostics.
- `openclaw status` currently reports Feishu `ON` and `OK`, gateway RPC probe `ok`, and no critical or warn findings in the embedded security summary.

## Upgrade Workflow

For future OpenClaw maintenance:

1. Update `nix-openclaw`.
2. Attempt to remove local override pieces before adding anything new.
3. Build the full Darwin configuration.
4. Switch the system.
5. Run the validation baseline.
6. Record any remaining local patch in this document.
