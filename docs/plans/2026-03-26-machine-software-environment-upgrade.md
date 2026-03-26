# Local Machine Software And Environment Upgrade Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade this macOS machine's Nix-managed system, Home Manager environment, Homebrew GUI layer, and OpenClaw deployment with controlled blast radius, explicit verification gates, and clear rollback points.

**Architecture:** Treat `flake.lock` as the version boundary for all persistent Nix-managed state, update inputs in small batches instead of one large jump, and validate each batch with a full Darwin build before switching. Keep OpenClaw under Nix authority at all times; use the CLI only for read-only diagnostics after rebuilds, and reconcile any runtime drift back into Nix before calling the upgrade complete.

**Tech Stack:** Nix flakes, `nixpkgs`, `nix-darwin`, Home Manager, Homebrew casks via nix-darwin, OpenClaw via `nix-openclaw` with local overlay in `modules/home/darwin/services/openclaw/package.nix`

---

### Task 1: Record Baseline And Recovery Points

**Files:**
- Modify: `flake.lock`
- Reference: `flake.nix`
- Reference: `user/darwin/README.md`
- Reference: `docs/plans/2026-03-26-openclaw-maintenance.md`

**Step 1: Confirm the tree is clean before touching lock state**

Run:

```bash
git status --short
```

Expected: no output.

**Step 2: Capture current dependency and runtime baselines**

Run:

```bash
nix flake metadata .
nix --version
darwin-rebuild --version
darwin-rebuild --list-generations
brew outdated || true
brew list --cask
openclaw --version
openclaw status
openclaw doctor
openclaw gateway status
proxy-status || true
```

Expected: commands succeed; current versions, active Darwin generations, GUI cask inventory, proxy state, and OpenClaw health are captured before any change.

**Step 3: Confirm the rollback commands before upgrading**

Run:

```bash
printf '%s\n' \
  'sudo darwin-rebuild switch --rollback' \
  'git restore flake.lock'
```

Expected: recovery path is explicit before any input update.

**Step 4: Commit the untouched baseline if needed**

Run:

```bash
git add docs/plans/2026-03-26-machine-software-environment-upgrade.md
git commit -m "docs: add local machine upgrade plan"
```

Expected: plan exists in history before execution starts.

### Task 2: Upgrade Non-Critical Flake Inputs First

**Files:**
- Modify: `flake.lock`
- Reference: `flake.nix`

**Step 1: Update low-risk supporting inputs only**

Run:

```bash
nix flake lock --update-input pre-commit-hooks
nix flake lock --update-input nuenv
nix flake lock --update-input catppuccin
```

Expected: only these inputs move in `flake.lock`.

**Step 2: Review the lock diff before building**

Run:

```bash
git diff -- flake.lock
```

Expected: diff contains only the selected input bumps.

**Step 3: Build the full system without switching**

Run:

```bash
nix build .#darwinConfigurations.stella.system
```

Expected: build succeeds with no new evaluation errors.

**Step 4: Run a lightweight flake sanity check if the build passed**

Run:

```bash
nix flake check
```

Expected: repository checks succeed, or any pre-existing failure is explicitly identified as unrelated to this input batch.

**Step 5: Commit the low-risk batch**

Run:

```bash
git add flake.lock
git commit -m "chore: update supporting flake inputs"
```

Expected: one isolated commit for the supporting batch.

### Task 3: Upgrade Core Darwin And User Environment Inputs

**Files:**
- Modify: `flake.lock`
- Reference: `outputs/darwin/default.nix`
- Reference: `profiles/system/stella.nix`
- Reference: `profiles/user/stella.nix`
- Reference: `modules/system/darwin/default.nix`
- Reference: `modules/home/darwin/default.nix`

**Step 1: Update the core environment inputs as one compatibility batch**

Run:

```bash
nix flake lock --update-input nixpkgs
nix flake lock --update-input nixpkgs-darwin
nix flake lock --update-input nix-darwin
nix flake lock --update-input home-manager
```

Expected: lockfile updates for the main system and user environment sources.

**Step 2: Review the exact dependency movement**

Run:

```bash
git diff -- flake.lock
```

Expected: changed nodes are limited to the four core inputs and their transitive locks.

**Step 3: Build first, switch second**

Run:

```bash
nix build .#darwinConfigurations.stella.system
sudo darwin-rebuild switch --flake .#stella
```

Expected: build succeeds before activation; switch completes without launchd or Home Manager activation failures.

**Step 4: Verify the main environment after switch**

Run:

```bash
darwin-rebuild --version
nix --version
which zsh
which bash
which node
which python3
which pnpm
which go
node --version
python3 --version
pnpm --version
go version
```

Expected: shells and managed base toolchains resolve correctly from the declarative environment, and version commands run without PATH conflicts.

**Step 5: Verify Home Manager owned shell environment and proxy helpers**

Run:

```bash
test -x ~/.nix-profile/bin/zsh || true
command -v proxy-on
command -v proxy-off
command -v proxy-status
```

Expected: Home Manager managed shell helpers remain available after activation.

**Step 6: Commit the core batch**

Run:

```bash
git add flake.lock
git commit -m "chore: update core darwin and home-manager inputs"
```

Expected: one rollback-friendly commit for the main platform upgrade.

### Task 4: Upgrade OpenClaw Through Nix Only

**Files:**
- Modify: `flake.lock`
- Reference: `modules/home/darwin/services/openclaw/default.nix`
- Reference: `modules/home/darwin/services/openclaw/package.nix`
- Reference: `modules/home/darwin/services/openclaw/runtime.nix`
- Reference: `modules/system/common/nixpkgs.nix`
- Reference: `docs/plans/2026-03-26-openclaw-maintenance.md`

**Step 1: Update only the OpenClaw flake input**

Run:

```bash
nix flake lock --update-input nix-openclaw
```

Expected: only `nix-openclaw` and its transitive lock entries change.

**Step 2: Re-check whether the local OpenClaw override can be reduced**

Review:

```bash
sed -n '1,260p' modules/home/darwin/services/openclaw/package.nix
sed -n '1,220p' docs/plans/2026-03-26-openclaw-maintenance.md
```

Expected: confirm whether upstream now covers any of these local fixes:
- source override to newer OpenClaw release
- `node-which`/pnpm closure workaround
- launchd label rewrite
- bundled plugin name rewrite

**Step 3: Build and switch the machine with the new OpenClaw input**

Run:

```bash
nix build .#darwinConfigurations.stella.system
sudo darwin-rebuild switch --flake .#stella
```

Expected: OpenClaw package builds successfully under the current local compatibility layer.

**Step 4: Validate OpenClaw with read-only diagnostics only**

Run:

```bash
openclaw --version
openclaw status
openclaw doctor
openclaw gateway status
openclaw channels status --probe
```

Expected: runtime is healthy enough for normal use; any warning is classified as blocking or known-non-blocking, and no imperative OpenClaw mutation is introduced.

**Step 5: Reconcile package policy if upstream fixed the insecure version gap**

Review:

```bash
sed -n '1,120p' modules/system/common/nixpkgs.nix
```

Expected: remove `openclaw-2026.3.12` from `permittedInsecurePackages` if it is no longer needed after the upgrade.

**Step 6: Commit the OpenClaw batch separately**

Run:

```bash
git add flake.lock modules/home/darwin/services/openclaw/package.nix modules/system/common/nixpkgs.nix docs/plans/2026-03-26-openclaw-maintenance.md
git commit -m "chore: update openclaw input and compatibility layer"
```

Expected: OpenClaw changes stay isolated from broader system upgrades.

### Task 5: Verify Homebrew GUI Layer And Managed Apps

**Files:**
- Reference: `modules/system/darwin/apps.nix`

**Step 1: Let nix-darwin drive GUI cask upgrades**

Run:

```bash
sudo darwin-rebuild switch --flake .#stella
```

Expected: declared casks in `modules/system/darwin/apps.nix` upgrade during activation because `homebrew.onActivation.upgrade = true`.

**Step 2: Check whether any unmanaged or failed GUI upgrades remain**

Run:

```bash
brew outdated || true
brew list --cask
```

Expected: remaining outdated items are either unmanaged, intentionally pinned, or explicitly deferred; the declared cask set is still present.

**Step 3: Smoke-test the declared GUI set**

Verify these apps launch and keep user state intact:
- ChatGPT
- Feishu
- Ghostty
- Google Chrome
- Visual Studio Code
- Zotero

Expected: apps open successfully and do not require emergency rollback.

**Step 4: Confirm the GUI layer still matches declarative ownership**

Review:

```bash
sed -n '1,220p' modules/system/darwin/apps.nix
```

Expected: any remaining GUI drift is operational only; the source of truth for managed casks remains `modules/system/darwin/apps.nix`.

### Task 6: Post-Upgrade Cleanup, Maintenance, And Rollback Notes

**Files:**
- Modify: `docs/plans/2026-03-26-openclaw-maintenance.md`
- Reference: `modules/system/darwin/maintenance/nix-store.nix`

**Step 1: Run a final end-to-end verification pass**

Run:

```bash
nix build .#darwinConfigurations.stella.system
nix flake check
openclaw status
openclaw doctor
openclaw gateway status
openclaw channels status --probe
proxy-status || true
```

Expected: build and repository checks still pass after all lock and config changes; critical services and connectivity checks are healthy.

**Step 2: Record any surviving local exceptions**

Update `docs/plans/2026-03-26-openclaw-maintenance.md` with:
- final OpenClaw runtime version
- any remaining local override in `package.nix`
- any known non-blocking warning still present after upgrade

Expected: repo documents all intentional drift from upstream packaging.

**Step 3: Clean old generations only after successful soak**

Run after at least one stable work session:

```bash
darwin-rebuild --list-generations
sudo nix-collect-garbage -d
```

Expected: older generations are removed only after confirming rollback is no longer needed.

**Step 4: Keep rollback options visible until the next successful day of use**

Run only if rollback is required:

```bash
sudo darwin-rebuild switch --rollback
git log --oneline --max-count=5
```

Expected: operator can revert either the active generation or the last lock/config commit quickly.

### Task 7: Final Success Gate

**Files:**
- Reference: `flake.lock`
- Reference: `modules/system/darwin/apps.nix`
- Reference: `modules/home/darwin/services/openclaw/default.nix`

**Step 1: Declare the upgrade successful only if all gates are met**

Success gates:
- `nix build .#darwinConfigurations.stella.system` passes
- `nix flake check` passes, or any remaining failure is confirmed pre-existing and unrelated
- `sudo darwin-rebuild switch --flake .#stella` completes successfully on the final target revision
- managed shells and toolchains resolve correctly: `zsh`, `bash`, `node`, `python3`, `pnpm`, `go`
- declared GUI casks remain installed and can launch normally
- `openclaw status`, `openclaw doctor`, `openclaw gateway status`, and `openclaw channels status --probe` are acceptable

Expected: the machine is upgraded only when both declarative rebuilds and runtime validation succeed.
