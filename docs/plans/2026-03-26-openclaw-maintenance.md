# OpenClaw Maintenance Baseline

## Current Baseline

- Nix-first installation and service management remain authoritative.
- Runtime target is `OpenClaw 2026.3.24`.
- Validation baseline:
  - `nix build .#darwinConfigurations.stella.system`
  - `sudo darwin-rebuild switch --flake .#stella`
  - `openclaw --version`
  - `openclaw status`
  - `openclaw doctor`
  - `openclaw gateway status`

## Local Override Scope

[`modules/home/darwin/services/openclaw/package.nix`](/Users/sue/nix/modules/home/darwin/services/openclaw/package.nix) is a temporary compatibility layer. It currently owns only these concerns:

1. Source override to upstream `v2026.3.24` (`cff6dc94`) until `nix-openclaw` ships the same or newer release.
2. Packaging compatibility fixes needed for Nix output closure validation.
3. Local runtime adjustments that keep the launchd label, bundled plugin names, and wrapper environment aligned with this repo's Nix-managed deployment.

Anything outside those three categories should not be added there.

## Removal Order

When updating `nix-openclaw`, try to delete local logic in this order:

1. Remove the source override if upstream already packages `2026.3.24` or newer.
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

## Upgrade Workflow

For future OpenClaw maintenance:

1. Update `nix-openclaw`.
2. Attempt to remove local override pieces before adding anything new.
3. Build the full Darwin configuration.
4. Switch the system.
5. Run the validation baseline.
6. Record any remaining local patch in this document.
