# Proxy Manual Takeover Design

**Date:** 2026-03-08

## Goal

Change the Darwin proxy setup so `darwin-rebuild switch` keeps the base proxy service available without automatically taking over traffic.

After this change:

- `mihomo` remains installed, configured, and persistently running
- `switch` does not automatically change macOS system proxy settings
- `switch` does not automatically inject `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` into shell or activation environments
- traffic takeover becomes an explicit manual step

## Context

The current configuration couples three behaviors that should be independent:

- the `mihomo` service lifecycle
- macOS system proxy takeover
- shell and activation-time proxy environment injection

That coupling creates an operational hazard: a Home Manager or OpenClaw change can unintentionally disturb the network path the current machine depends on for the build itself.

The repository already has the right conceptual split available in code:

- `user/darwin/services/mihomo/default.nix` manages package, config link, and launchd
- `system/darwin/system/proxy-tools.nix` exposes explicit manual commands
- `system/darwin/system/activation.nix` currently turns those manual commands into automatic activation behavior
- `system/darwin/apps.nix` currently injects proxy env into Homebrew activation

The design goal is to keep the service layer declarative while moving traffic takeover back to explicit operator intent.

## Chosen Approach

Adopt a soft separation without restructuring the module tree:

- keep `mihomo` as a persistent declarative service
- remove automatic system proxy mutation from activation
- remove automatic shell proxy variable injection
- remove activation-time Homebrew proxy env injection
- keep system takeover as explicit commands
- add explicit shell-only proxy export helpers for manual use

This preserves the current file layout and minimizes behavioral risk while making the default state safe.

## Architecture

### 1. Base Proxy Service Layer

`user/darwin/services/mihomo/default.nix` remains responsible for:

- installing `pkgs.mihomo`
- linking `~/.config/mihomo/config.yaml`
- keeping the `launchd` agent enabled and persistent

This layer is allowed to survive `switch` because it does not itself reroute traffic. It only ensures that a local proxy endpoint is available when the user decides to use it.

### 2. Manual Traffic Takeover Layer

`system/darwin/system/proxy-tools.nix` remains the manual control surface for macOS system proxy takeover:

- `proxy-on`
- `proxy-off`
- `proxy-status`

These commands stay available in `environment.systemPackages`, but they are no longer invoked automatically during activation.

The same module should also add shell-oriented helpers:

- `proxy-env-on`
- `proxy-env-off`
- `proxy-env-status`

`proxy-env-on` should print `export` statements so the caller can opt in with:

```bash
eval "$(proxy-env-on)"
```

`proxy-env-off` should print `unset` statements so the caller can remove takeover from the current shell only.

### 3. Activation Boundary

`system/darwin/system/activation.nix` must stop applying proxy state during `switch`.

The activation phase should no longer call either:

- `proxy-on`
- `proxy-off`

That means `darwin-rebuild switch` becomes a deployment action only. It no longer asserts what the current system proxy state should be.

### 4. Shell And Activation Env Boundary

`user/darwin/services/mihomo/default.nix` must stop setting `home.sessionVariables` for proxy env.

`system/darwin/apps.nix` must stop exporting proxy variables into Homebrew activation.

This ensures that:

- a new shell starts without implicit proxy takeover
- activation scripts do not silently change the network path used during rebuild
- OpenClaw and Home Manager changes do not automatically disturb a working connection

## Configuration Semantics

`vars/networking/proxy.nix` should keep proxy endpoint and `no_proxy` construction as shared data, but its policy fields should no longer mean "automatic default takeover during switch."

Recommended semantic shift:

- treat policy values as metadata for manual tools and documentation
- avoid wiring those values directly into activation or session env side effects

If the existing `systemDefault`, `cliDefault`, and `homebrewEnv` fields are retained for compatibility, they should default to the safe non-automatic behavior and stop driving activation/session injection paths.

## User Workflow

### Default After `switch`

After `darwin-rebuild switch --flake .`:

- `mihomo` is running
- its config is deployed
- system proxy state remains whatever it was before the switch
- shell env remains free of implicit proxy variables

### Manual System Takeover

When the user wants macOS traffic to go through `mihomo`:

```bash
proxy-on
```

To revert:

```bash
proxy-off
```

### Manual Shell Takeover

When the user wants only the current shell to use the proxy:

```bash
eval "$(proxy-env-on)"
```

To remove those variables from the current shell:

```bash
eval "$(proxy-env-off)"
```

To inspect current shell-level proxy env:

```bash
proxy-env-status
```

## Risks

- Documentation may still claim that applying the config automatically enables the proxy.
- Existing operators may rely on implicit proxy env in fresh shells.
- If policy names remain unchanged, they may continue to imply automatic behavior even after the implementation is made manual.

## Risk Controls

- Update deployment and service documentation to say that `mihomo` is persistent but takeover is manual.
- Keep `proxy-on` / `proxy-off` behavior unchanged so the operator workflow remains simple.
- Add shell helper commands rather than removing env-based usage entirely.
- Validate behavior specifically around `switch`, not only around service health.

## Validation

The change is complete when all of the following are true:

- `darwin-rebuild switch --flake .` does not alter current system proxy state
- `mihomo` is still installed, configured, and running after switch
- a fresh shell does not contain injected proxy env by default
- `proxy-on` and `proxy-off` still toggle macOS system proxy correctly
- `proxy-env-on` and `proxy-env-off` let the current shell opt in and out explicitly
- OpenClaw or Home Manager changes can be deployed without unintentionally disturbing the current working network path
