# Phase C Architecture Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan
> task-by-task.

**Goal:** Complete Phase C by retiring the temporary compatibility layer, fully deleting `vars/`,
moving canonical module ownership under `modules/`, splitting OpenClaw into clear submodules, and
removing or excluding `.tmp-openclaw-local/` without losing rollback clarity.

**Architecture:** Execute Phase C as a sequence of small, validated cutovers. First remove the
already-redundant `vars/` surface. Then move the remaining canonical home and system modules under
`modules/`. Finally split the OpenClaw monolith into `package`, `plugins`, `config`, `secrets`, and
`runtime`, cut service imports to the canonical path, remove the last shims, and do only the narrow
doc updates required by the new structure.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager, launchd, nix-openclaw, OpenClaw CLI

---

## OpenClaw Migration Order

Use this order and do not reorder it during implementation:

1. `package`
2. `plugins`
3. `config`
4. `secrets`
5. `runtime`

Rationale:

- `package` is the narrowest extraction and has the lowest behavior risk.
- `plugins` defines IDs, sources, install metadata, and packaging helpers that `config` consumes.
- `config` can then become declarative and data-oriented instead of owning fetch/build logic.
- `secrets` should be extracted before `runtime` so the wrapper and launchd code only consume a
  local secret-loading contract.
- `runtime` is last because it depends on package, plugins, config, and secrets, and it is the
  highest-risk cutover.

## Checkpoints

Use these checkpoint names throughout implementation:

- `P0` Phase A+B baseline commit
- `P1` `vars/` retired
- `P2` canonical home and system modules moved under `modules/`
- `P3` OpenClaw `package` and `plugins` extracted
- `P4` OpenClaw `config` and `secrets` extracted
- `P5` OpenClaw `runtime` extracted and legacy OpenClaw entrypoint removed
- `P6` `.tmp-openclaw-local/` removed or excluded and narrow docs updated

At each checkpoint:

1. run the validation commands listed for that task
2. run `sudo darwin-rebuild switch --flake .#stella` if the task changes active configuration
3. record the new generation with `darwin-rebuild --list-generations | tail -n 5`
4. commit before continuing

Rollback rule:

- if the new generation is bad, run `sudo darwin-rebuild switch --rollback`
- if Home Manager state is partially applied, run `home-manager switch --rollback`
- if the code change itself should be reverted after the checkpoint commit, use
  `git revert <commit>` rather than rewriting history

### Task 1: Freeze the baseline and capture rollback state

**Files:**

- Modify: none
- Verify: `flake.nix`
- Verify: `profiles/system/stella.nix`
- Verify: `profiles/user/stella.nix`

**Step 1: Confirm the worktree state before Phase C**

Run: `git status --short` Expected: only the known Phase A+B changes, formatting sweep changes, and
known pre-existing user changes are present.

**Step 2: Capture the current passing baseline**

Run: `nix flake check` Expected: exit 0

**Step 3: Capture the current active generations**

Run: `darwin-rebuild --list-generations | tail -n 5` Expected: the latest successful Phase A+B
generation is visible

Run: `home-manager generations | tail -n 5` Expected: recent Home Manager generations are visible

**Step 4: Commit checkpoint `P0`**

```bash
git add .
git commit -m "refactor: checkpoint phase a+b baseline"
```

### Task 2: Retire `vars/` completely

**Files:**

- Delete: `vars/default.nix`
- Delete: `vars/toolchains.nix`
- Delete: `vars/networking/default.nix`
- Delete: `vars/networking/dns.nix`
- Delete: `vars/networking/hosts.nix`
- Delete: `vars/networking/mihomo.nix`
- Delete: `vars/networking/proxy.nix`
- Delete: `vars/networking/ssh.nix`
- Delete: `vars/README.md`
- Delete: `vars/`
- Verify: `outputs/default.nix`
- Verify: `modules/home/base.nix`
- Verify: `modules/home/darwin/shell.nix`
- Verify: `system/common/users.nix`
- Verify: `system/darwin/system/proxy-tools.nix`
- Verify: `user/common/core/git.nix`
- Verify: `user/common/core/tooling/toolchain.nix`
- Verify: `user/darwin/services/openclaw/default.nix`

**Step 1: Confirm there are no live imports that still need `vars/`**

Run: `rg -n "vars/" . -g '*.nix'` Expected: matches are limited to the compatibility files being
deleted or historical docs

**Step 2: Delete the `vars/` compatibility surface**

Remove the entire `vars/` tree once no active Nix evaluation path depends on it.

**Step 3: Verify the canonical shared surface is still `infra/`**

Run:
`rg -n "import ../infra|import ../../infra|import ../../../infra|myvars = import ../infra" . -g '*.nix'`
Expected: canonical imports point at `infra/` and `outputs/default.nix` still builds `myvars` from
`infra`

**Step 4: Run evaluation validation**

Run: `nix flake check --no-build` Expected: exit 0

Run: `nix eval .#darwinConfigurations.stella.config.networking.hostName` Expected: `"stella"` or the
current configured host name

**Step 5: Activate checkpoint `P1`**

Run: `sudo darwin-rebuild switch --flake .#stella` Expected: exit 0

**Step 6: Commit checkpoint `P1`**

```bash
git add -A
git commit -m "refactor: retire vars compatibility surface"
```

### Task 3: Move canonical home modules under `modules/home/`

**Files:**

- Create: `modules/home/common.nix`
- Create: `modules/home/core/packages.nix`
- Create: `modules/home/core/git.nix`
- Create: `modules/home/core/cli-experience.nix`
- Create: `modules/home/core/neovim.nix`
- Create: `modules/home/core/pip.nix`
- Create: `modules/home/core/starship.nix`
- Create: `modules/home/core/theme.nix`
- Create: `modules/home/core/tooling/toolchain.nix`
- Create: `modules/home/core/tooling/infra.nix`
- Create: `modules/home/core/scripts/devshell-init`
- Create: `modules/home/core/scripts/devshell-attach`
- Create: `modules/home/darwin/apps/ghostty.nix`
- Create: `modules/home/darwin/config.nu`
- Create: `modules/home/darwin/services/mihomo/default.nix`
- Create: `modules/home/darwin/services/mihomo/config.yaml`
- Create: `modules/home/darwin/services/mihomo/config.yaml.example`
- Create: `modules/home/darwin/services/mihomo/config.local.yaml`
- Create: `modules/home/darwin/services/mihomo/README.md`
- Modify: `modules/home/base.nix`
- Modify: `modules/home/core/default.nix`
- Modify: `modules/home/darwin/default.nix`
- Modify: `modules/home/darwin/shell.nix`
- Modify: `modules/home/darwin/services/default.nix`
- Delete: `user/common/home.nix`
- Delete: `user/common/core/packages.nix`
- Delete: `user/common/core/git.nix`
- Delete: `user/common/core/cli-experience.nix`
- Delete: `user/common/core/neovim.nix`
- Delete: `user/common/core/pip.nix`
- Delete: `user/common/core/starship.nix`
- Delete: `user/common/core/theme.nix`
- Delete: `user/common/core/tooling/toolchain.nix`
- Delete: `user/common/core/tooling/infra.nix`
- Delete: `user/common/core/scripts/devshell-init`
- Delete: `user/common/core/scripts/devshell-attach`
- Delete: `user/common/core/shells/config.nu`
- Delete: `user/common/core/shells/readme`
- Delete: `user/common/core/default.nix`
- Delete: `user/common/core/shells/default.nix`
- Delete: `user/darwin/ghostty.nix`
- Delete: `user/darwin/profiles/shell.nix`
- Verify: `profiles/user/stella.nix`
- Verify: `hosts/stella/home.nix`

**Step 1: Create canonical home files under `modules/home/`**

Move content, not behavior:

- `user/common/home.nix` → `modules/home/common.nix`
- `user/common/core/*.nix` → `modules/home/core/*.nix`
- `user/common/core/tooling/*.nix` → `modules/home/core/tooling/*.nix`
- `user/common/core/scripts/*` → `modules/home/core/scripts/*`
- `user/darwin/ghostty.nix` → `modules/home/darwin/apps/ghostty.nix`
- `user/common/core/shells/config.nu` → `modules/home/darwin/config.nu`
- `user/darwin/services/mihomo/*` → `modules/home/darwin/services/mihomo/*`

**Step 2: Repoint the canonical manifests**

Update:

- `modules/home/base.nix` to import `./common.nix`
- `modules/home/core/default.nix` to import only `./` local canonical files
- `modules/home/darwin/default.nix` to import `./apps/ghostty.nix`
- `modules/home/darwin/shell.nix` to read `./config.nu`
- `modules/home/darwin/services/default.nix` to import canonical Mihomo and keep OpenClaw on the
  temporary legacy path until the OpenClaw split is complete

**Step 3: Remove home shims that are now redundant**

Delete:

- `user/common/core/default.nix`
- `user/common/core/shells/default.nix`
- `user/darwin/profiles/shell.nix`

Keep for now:

- `user/darwin/default.nix`
- `user/darwin/services/default.nix`
- `user/darwin/services/openclaw/default.nix`

**Step 4: Validate home-module cutover**

Run:
`rg -n "user/common/home.nix|user/common/core/|user/darwin/ghostty.nix|user/darwin/services/mihomo/" modules profiles outputs -g '*.nix'`
Expected: no matches except the intentionally deferred OpenClaw path

Run: `nix flake check --no-build` Expected: exit 0

Run:
`env -u __HM_SESS_VARS_SOURCED -u __HM_ZSH_SESS_VARS_SOURCED bash -lc 'printf "%s\n%s\n%s\n" "$HTTP_PROXY" "$NPM_CONFIG_PREFIX" "$PATH"'`
Expected: proxy env and shell env are still present

**Step 5: Activate checkpoint `P2-home`**

Run: `sudo darwin-rebuild switch --flake .#stella` Expected: exit 0

**Step 6: Commit the home-module cutover**

```bash
git add -A
git commit -m "refactor: move canonical home modules under modules"
```

### Task 4: Move canonical system modules under `modules/system/`

**Files:**

- Create: `modules/system/common/fonts.nix`
- Create: `modules/system/common/nix.nix`
- Create: `modules/system/common/nixpkgs.nix`
- Create: `modules/system/common/overlays.nix`
- Create: `modules/system/common/security.nix`
- Create: `modules/system/common/system-packages.nix`
- Create: `modules/system/common/users.nix`
- Create: `modules/system/darwin/apps.nix`
- Create: `modules/system/darwin/nix-determinate.nix`
- Create: `modules/system/darwin/security.nix`
- Create: `modules/system/darwin/users.nix`
- Create: `modules/system/darwin/system.nix`
- Create: `modules/system/darwin/maintenance/default.nix`
- Create: `modules/system/darwin/maintenance/nix-store.nix`
- Create: `modules/system/darwin/system/activation.nix`
- Create: `modules/system/darwin/system/defaults-ui.nix`
- Create: `modules/system/darwin/system/input.nix`
- Create: `modules/system/darwin/system/proxy-tools.nix`
- Create: `modules/system/darwin/system/security-pam.nix`
- Create: `modules/system/darwin/system/timezone.nix`
- Modify: `modules/system/common.nix`
- Modify: `modules/system/darwin/default.nix`
- Delete: `system/common/fonts.nix`
- Delete: `system/common/nix.nix`
- Delete: `system/common/nixpkgs.nix`
- Delete: `system/common/overlays.nix`
- Delete: `system/common/security.nix`
- Delete: `system/common/system-packages.nix`
- Delete: `system/common/users.nix`
- Delete: `system/common/default.nix`
- Delete: `system/darwin/apps.nix`
- Delete: `system/darwin/nix-determinate.nix`
- Delete: `system/darwin/security.nix`
- Delete: `system/darwin/users.nix`
- Delete: `system/darwin/system.nix`
- Delete: `system/darwin/maintenance/default.nix`
- Delete: `system/darwin/maintenance/nix-store.nix`
- Delete: `system/darwin/system/activation.nix`
- Delete: `system/darwin/system/defaults-ui.nix`
- Delete: `system/darwin/system/input.nix`
- Delete: `system/darwin/system/proxy-tools.nix`
- Delete: `system/darwin/system/security-pam.nix`
- Delete: `system/darwin/system/timezone.nix`
- Delete: `system/darwin/default.nix`
- Verify: `profiles/system/stella.nix`
- Verify: `hosts/stella/system.nix`

**Step 1: Move system files into the canonical tree**

Move content, not behavior:

- `system/common/*.nix` → `modules/system/common/*.nix`
- `system/darwin/*.nix` → `modules/system/darwin/*.nix`
- `system/darwin/system/*.nix` → `modules/system/darwin/system/*.nix`
- `system/darwin/maintenance/*.nix` → `modules/system/darwin/maintenance/*.nix`

Important:

- when moving `system/darwin/apps.nix`, preserve the current live file contents exactly
- do not “clean up” its existing user-authored delta during the move

**Step 2: Repoint the canonical manifests**

Update:

- `modules/system/common.nix` to import only `./common/*.nix`
- `modules/system/darwin/default.nix` to import only `./` local canonical system files

**Step 3: Remove the system compatibility shims**

Delete:

- `system/common/default.nix`
- `system/darwin/default.nix`

**Step 4: Validate system-module cutover**

Run: `rg -n "system/common/|system/darwin/" modules profiles outputs -g '*.nix'` Expected: no
matches

Run: `nix flake check --no-build` Expected: exit 0

Run: `nix eval .#darwinConfigurations.stella.config.users.users.sue.home` Expected: `"/Users/sue"`

**Step 5: Activate checkpoint `P2`**

Run: `sudo darwin-rebuild switch --flake .#stella` Expected: exit 0

**Step 6: Commit the system-module cutover**

```bash
git add -A
git commit -m "refactor: move canonical system modules under modules"
```

### Task 5: Extract OpenClaw `package` and `plugins`

**Files:**

- Create: `modules/home/darwin/services/openclaw/default.nix`
- Create: `modules/home/darwin/services/openclaw/package.nix`
- Create: `modules/home/darwin/services/openclaw/plugins.nix`
- Create: `modules/home/darwin/services/openclaw/documents/AGENTS.md`
- Create: `modules/home/darwin/services/openclaw/documents/TOOLS.md`
- Modify: `modules/home/darwin/services/default.nix`
- Modify: `user/darwin/services/openclaw/default.nix`
- Delete: `user/darwin/services/openclaw/documents/AGENTS.md`
- Delete: `user/darwin/services/openclaw/documents/TOOLS.md`
- Verify: `user/darwin/services/openclaw/default.nix`

**Step 1: Create the canonical OpenClaw module root**

Create `modules/home/darwin/services/openclaw/default.nix` as the canonical entrypoint. It should
import `package.nix` and `plugins.nix` first, while still leaving `config`, `secrets`, and `runtime`
in the legacy file until later tasks.

**Step 2: Extract `package.nix`**

Move these definitions out of the monolith:

- `upstreamPackages`
- `fixedGateway`
- `openclawPackageDir`

`package.nix` should own:

- the pinned `nix-openclaw` package selection
- package-level `overrideAttrs`
- the launchd-label patching
- the Baileys `long` closure fix
- package-level wrapper defaults that are truly package concerns

**Step 3: Extract `plugins.nix`**

Move these definitions out of the monolith:

- `feishuPluginId`
- `memoryLancedbProId`
- `memoryLancedbProVersion`
- `memoryLancedbProRev`
- `memoryLancedbProSrc`
- `memoryLancedbProInstall`
- `tavilyPluginId`
- `tavilyPluginVersion`
- `tavilyPluginRev`
- `tavilyPluginSrc`
- `tavilyPluginInstall`

`plugins.nix` should expose plugin IDs, sources, versions, and install metadata, but not generate
the final `openclaw.json` yet.

**Step 4: Point the service manifest at the canonical OpenClaw root**

Update `modules/home/darwin/services/default.nix` to import:

- `./mihomo/default.nix`
- `./openclaw/default.nix`

Temporarily convert `user/darwin/services/openclaw/default.nix` into a shim that imports the new
canonical OpenClaw module. Do not delete it yet.

**Step 5: Validate `package` and `plugins` extraction**

Run: `nix flake check --no-build` Expected: exit 0

Run:
`nix eval --raw .#darwinConfigurations.stella.config.home-manager.users.sue.programs.openclaw.package.pname`
Expected: `openclaw-gateway` or the current package pname

Run:
`nix eval .#darwinConfigurations.stella.config.home-manager.users.sue.programs.openclaw.instances.default.enable`
Expected: `true`

**Step 6: Activate checkpoint `P3`**

Run: `sudo darwin-rebuild switch --flake .#stella` Expected: exit 0

**Step 7: Commit checkpoint `P3`**

```bash
git add -A
git commit -m "refactor: extract openclaw package and plugins"
```

### Task 6: Extract OpenClaw `config` and `secrets`

**Files:**

- Create: `modules/home/darwin/services/openclaw/config.nix`
- Create: `modules/home/darwin/services/openclaw/secrets.nix`
- Modify: `modules/home/darwin/services/openclaw/default.nix`
- Modify: `user/darwin/services/openclaw/default.nix`

**Step 1: Extract `config.nix`**

Move these definitions out of the monolith:

- `feishuAppId`
- `managedOpenclawConfig`
- `managedOpenclawHmConfig`
- `declarativeOpenclawConfig`

`config.nix` should own:

- generated `openclaw.json`
- assistants
- channels
- tool policy
- plugin enablement references
- stable defaults for the Home Manager instance

It should consume package and plugin metadata, not redefine them.

**Step 2: Extract `secrets.nix`**

Move secret-loading contracts out of the monolith:

- `.openclaw/.env` out-of-store symlink
- runtime secret file locations under `~/.secrets`
- helper shell fragments or helper attrs that load:
  - `FEISHU_APP_ID`
  - `FEISHU_APP_SECRET`
  - `JINA_API_KEY`
  - `TAVILY_API_KEY`
  - `FIRECRAWL_API_KEY`

`secrets.nix` must not store secret values in Nix. It should only define runtime expectations and
helper contracts.

**Step 3: Keep the legacy entrypoint as a shim for one more step**

`user/darwin/services/openclaw/default.nix` should continue to forward to the canonical
`modules/home/darwin/services/openclaw/default.nix` until the runtime cutover is complete.

**Step 4: Validate `config` and `secrets` extraction**

Run: `nix flake check --no-build` Expected: exit 0

Run:
`nix eval --json .#darwinConfigurations.stella.config.home-manager.users.sue.programs.openclaw.instances.default.config.tools`
Expected: the current tool policy JSON is returned

Run: `readlink ~/.openclaw/.env` Expected: points to `~/.secrets/openclaw.env`

**Step 5: Activate checkpoint `P4`**

Run: `sudo darwin-rebuild switch --flake .#stella` Expected: exit 0

**Step 6: Commit checkpoint `P4`**

```bash
git add -A
git commit -m "refactor: extract openclaw config and secrets"
```

### Task 7: Extract OpenClaw `runtime` and remove the remaining home shims

**Files:**

- Create: `modules/home/darwin/services/openclaw/runtime.nix`
- Modify: `modules/home/darwin/services/openclaw/default.nix`
- Delete: `user/darwin/services/openclaw/default.nix`
- Delete: `user/darwin/services/default.nix`
- Delete: `user/darwin/default.nix`
- Verify: `modules/home/darwin/services/default.nix`
- Verify: `profiles/user/stella.nix`

**Step 1: Extract `runtime.nix`**

Move these runtime-only concerns out of the monolith:

- `proxyEnv`
- `gatewayLaunchdPath`
- `.local/bin/openclaw` wrapper
- launchd `ProgramArguments` override
- launchd PATH override
- activation hooks:
  - `openclawDeclarativeConfigLink`
  - `openclawMemoryLancedbProInstall`
  - `openclawTavilyInstall`
  - `openclawRuntimeHygiene`
  - `openclawAgentsSkillsMirror`
- `.openclaw/identity/.keep`

`runtime.nix` should consume outputs from `package`, `plugins`, `config`, and `secrets`. It should
not recreate them.

**Step 2: Cut the final home-service imports to canonical paths**

Ensure:

- `modules/home/darwin/services/default.nix` imports only canonical local service files
- no canonical `modules/*` file imports `user/*` paths anymore

**Step 3: Remove the remaining user-level shims**

Delete:

- `user/darwin/services/openclaw/default.nix`
- `user/darwin/services/default.nix`
- `user/darwin/default.nix`

If `user/darwin/profiles/default.nix` becomes orphaned and unused, delete it in this step too.

**Step 4: Validate the runtime cutover**

Run:
`rg -n "user/darwin/services/openclaw|user/darwin/services/default.nix|user/darwin/default.nix" modules profiles outputs -g '*.nix'`
Expected: no matches

Run: `nix flake check` Expected: exit 0

Run: `sudo darwin-rebuild switch --flake .#stella` Expected: exit 0

Run: `openclaw status` Expected: gateway reachable and no new critical runtime regressions

Run: `openclaw gateway status` Expected: running and probe ok

Run: `openclaw doctor` Expected: no new critical findings

Run:
`launchctl print gui/$(id -u)/com.steipete.openclaw.gateway | rg 'state =|pid =|last exit code ='`
Expected: running state and healthy pid or last exit `0`

Run:
`env -u __HM_SESS_VARS_SOURCED -u __HM_ZSH_SESS_VARS_SOURCED zsh -lc 'printf "%s\n%s\n%s\n" "$HTTP_PROXY" "$NPM_CONFIG_PREFIX" "$PATH"'`
Expected: proxy env and shell env still present

**Step 5: Commit checkpoint `P5`**

```bash
git add -A
git commit -m "refactor: split openclaw runtime and remove home shims"
```

### Task 8: Remove or exclude `.tmp-openclaw-local/` and apply narrow doc updates

**Files:**

- Delete: `.tmp-openclaw-local/flake.nix`
- Delete: `.tmp-openclaw-local/flake.lock`
- Delete: `.tmp-openclaw-local/openclaw.env`
- Delete: `.tmp-openclaw-local/telegram-bot-token`
- Delete: `.tmp-openclaw-local/documents/AGENTS.md`
- Delete: `.tmp-openclaw-local/documents/SOUL.md`
- Delete: `.tmp-openclaw-local/documents/TOOLS.md`
- Modify: `.gitignore`
- Modify: `.prettierignore`
- Modify: `DEPLOYMENT.md`
- Modify: `user/darwin/README.md`
- Modify: `docs/plans/2026-03-10-phase-c-architecture-design.md`
- Verify: `docs/plans/2026-03-10-phase-c-architecture.md`

**Step 1: Prefer full removal of `.tmp-openclaw-local/`**

Delete the tracked `.tmp-openclaw-local/` tree if no current Nix path, doc, or local test flow still
depends on it.

Fallback only if removal is blocked by a still-needed local workflow:

- add `.tmp-openclaw-local/` to `.gitignore`
- add `.tmp-openclaw-local/` to `.prettierignore`
- state explicitly in the commit message that it is excluded from authoritative repo management

**Step 2: Apply only the narrow docs updates required by the final canonical structure**

Update docs so they reflect:

- `infra/` replacing `vars/`
- canonical `modules/` ownership
- OpenClaw ownership split
- `.tmp-openclaw-local/` removal or exclusion policy

Do not do unrelated prose cleanup.

**Step 3: Final validation**

Run:
`rg -n "vars/|user/common/core/default.nix|user/common/core/shells/default.nix|user/darwin/default.nix|system/common/default.nix|system/darwin/default.nix|\\.tmp-openclaw-local/" .`
Expected: only historical plan docs or intentional documentation references remain

Run: `nix flake check` Expected: exit 0

Run: `sudo darwin-rebuild switch --flake .#stella` Expected: exit 0

Run: `openclaw status && openclaw gateway status && openclaw doctor` Expected: exit 0

**Step 4: Commit checkpoint `P6`**

```bash
git add -A
git commit -m "chore: finalize phase c structure and docs"
```

## Commit Policy

Safe to combine in one commit:

- retiring `vars/`
- narrow doc updates
- `.tmp-openclaw-local/` deletion if no code still references it

Should be separate commits:

- moving canonical home modules under `modules/home/`
- moving canonical system modules under `modules/system/`
- extracting OpenClaw `package` and `plugins`
- extracting OpenClaw `config` and `secrets`
- extracting OpenClaw `runtime` and removing the remaining home shims

Do not combine the final OpenClaw runtime cutover with unrelated docs or repo-hygiene changes.

## Recommended Git Commit Sequence

1. `refactor: checkpoint phase a+b baseline`
2. `refactor: retire vars compatibility surface`
3. `refactor: move canonical home modules under modules`
4. `refactor: move canonical system modules under modules`
5. `refactor: extract openclaw package and plugins`
6. `refactor: extract openclaw config and secrets`
7. `refactor: split openclaw runtime and remove home shims`
8. `chore: finalize phase c structure and docs`

If `.tmp-openclaw-local/` removal turns out to be operationally sensitive, split commit 8 into:

- `chore: remove tmp-openclaw-local from repo management`
- `docs: update canonical phase c paths`

## Highest-Risk Steps

1. OpenClaw `runtime` extraction
   - highest risk because launchd, wrapper env, proxy inheritance, skill mirroring, and plugin
     runtime hygiene all converge here

2. OpenClaw `plugins` extraction
   - high risk because plugin packaging and activation-time install behavior are currently tangled
     together

3. Canonical move of `system/darwin/apps.nix`
   - moderate risk because it contains a pre-existing user-authored change that must be preserved
     exactly during the move

4. `.tmp-openclaw-local/` removal
   - moderate risk because the tracked tree looks stale, but may still be referenced by ad hoc local
     workflows not represented in Nix

5. Shim deletion timing
   - moderate risk because deleting shims before all canonical manifests are rewired will break
     evaluation immediately

## Final Migration Checklist

- [ ] `P0` baseline committed and generations recorded
- [ ] `vars/` deleted and `P1` validated
- [ ] canonical home files moved under `modules/home/`
- [ ] canonical system files moved under `modules/system/`
- [ ] OpenClaw `package` extracted
- [ ] OpenClaw `plugins` extracted
- [ ] OpenClaw `config` extracted
- [ ] OpenClaw `secrets` extracted
- [ ] OpenClaw `runtime` extracted
- [ ] remaining user-level shims deleted
- [ ] remaining system-level shims deleted
- [ ] `.tmp-openclaw-local/` removed or explicitly excluded
- [ ] narrow docs updated
- [ ] final `nix flake check` passes
- [ ] final `darwin-rebuild switch --flake .#stella` passes
- [ ] final `openclaw status`, `openclaw gateway status`, and `openclaw doctor` pass
