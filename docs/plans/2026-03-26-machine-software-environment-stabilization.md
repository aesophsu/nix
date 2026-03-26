# Local Machine Software And Environment Stabilization Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Stabilize the machine after the completed system upgrade by validating day-2 behavior, documenting the new steady state, and reducing temporary compatibility debt without risking the working environment.

**Architecture:** Treat the current `main` branch and active Darwin generation as the new baseline. Separate work into three tracks: short soak validation, declarative cleanup, and deferred upgrade candidates. Keep OpenClaw under Nix authority and only attempt debt reduction when each removal is backed by a fresh build and runtime verification pass.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager, Homebrew casks via nix-darwin, OpenClaw via `nix-openclaw`, launchd, shell PATH/session wiring

---

### Task 1: Record The New Post-Upgrade Baseline

**Files:**
- Modify: `docs/plans/2026-03-26-openclaw-maintenance.md`
- Reference: `docs/plans/2026-03-26-machine-software-environment-upgrade.md`

**Step 1: Capture the final declarative baseline**

Run:

```bash
git log --oneline --max-count=4
nix flake metadata .
```

Expected: the current baseline includes the merged upgrade commits and the active flake input set.

**Step 2: Capture the runtime baseline**

Run:

```bash
openclaw --version
openclaw status
openclaw gateway status
proxy-status || true
env -i HOME="$HOME" USER="$USER" SHELL=/run/current-system/sw/bin/bash TERM=xterm-256color /run/current-system/sw/bin/bash -lc 'command -v brew && brew --version | head -n 1'
```

Expected: current OpenClaw version, gateway state, proxy state, and `brew` PATH visibility are documented as the new steady state.

**Step 3: Update maintenance notes**

Record in `docs/plans/2026-03-26-openclaw-maintenance.md`:
- final merged OpenClaw runtime version
- remaining local override files
- remaining known non-blocking warnings
- note that Homebrew CLI visibility now depends on Home Manager PATH exposure, not manual shell edits

Expected: the repo documents the current steady state clearly enough for the next maintenance cycle.

### Task 2: Run A Short Soak Validation Window

**Files:**
- Reference: `modules/home/darwin/shell.nix`
- Reference: `modules/system/darwin/apps.nix`

**Step 1: Validate shell and toolchain behavior in normal usage**

Run:

```bash
zsh -lc 'command -v brew; command -v node; command -v python3; command -v go'
bash -lc 'command -v brew; command -v node; command -v python3; command -v go'
```

Expected: both managed shells expose the expected toolchain and Homebrew path.

**Step 2: Validate GUI app continuity**

Verify manually:
- ChatGPT launches
- Feishu launches and remains logged in
- Ghostty launches with existing settings
- Visual Studio Code launches with extensions intact
- Zotero launches with library intact

Expected: GUI state survives the upgrade without recovery work.

**Step 3: Validate OpenClaw day-2 behavior**

Run:

```bash
openclaw doctor
openclaw channels status --probe
openclaw gateway status
```

Expected: Feishu remains healthy, gateway RPC probe remains `ok`, and no new warnings appear beyond the documented non-blocking set.

### Task 3: Reduce The Most Obvious Temporary Debt

**Files:**
- Modify: `docs/plans/2026-03-26-openclaw-maintenance.md`
- Reference: `overlays/direnv-darwin-cgo-fix.nix`
- Reference: `modules/home/darwin/services/openclaw/package.nix`
- Reference: `outputs/default.nix`

**Step 1: Open tracking notes for temporary compatibility layers**

Review:

```bash
sed -n '1,120p' overlays/direnv-darwin-cgo-fix.nix
sed -n '1,320p' modules/home/darwin/services/openclaw/package.nix
sed -n '1,140p' outputs/default.nix
```

Expected: current temporary debt is explicitly identified:
- Darwin-only `direnv` overlay workaround
- OpenClaw packaging compatibility layer
- flake check scope reduction for repo-wide `prettier`

**Step 2: Document removal triggers instead of removing blindly**

Add explicit removal criteria to `docs/plans/2026-03-26-openclaw-maintenance.md`:
- remove `direnv` overlay only after upstream `nixpkgs-darwin` no longer injects the broken `CGO_ENABLED=0` combination
- restore full flake `prettier` coverage only after repository-wide formatting drift is handled in a dedicated branch
- reduce `openclaw/package.nix` only when `nix-openclaw` picks up the required runtime fixes upstream

Expected: future cleanup work has clear entry criteria and does not depend on memory.

### Task 4: Prepare The Next Upgrade Candidate Batch

**Files:**
- Reference: `flake.nix`
- Reference: `flake.lock`
- Reference: `modules/system/common/nixpkgs.nix`

**Step 1: Identify what did not move in this cycle**

Run:

```bash
nix flake metadata .
```

Expected: confirm that `nixpkgs`, `home-manager`, and `nix-openclaw` were unchanged in the final merged state.

**Step 2: Create a deferred candidate list**

Record the next candidates for a future branch:
- `nixpkgs`
- `home-manager`
- `nix-openclaw`
- full-repo formatting normalization

Expected: the next maintenance cycle starts from a known deferred backlog instead of rediscovering it.

Current deferred baseline after the merged upgrade:
- `nixpkgs` remains at `46db2e0`
- `home-manager` remains at `1eb0549`
- `nix-openclaw` remains at `64d4106`
- full-repo `prettier` enforcement remains intentionally deferred until a dedicated formatting branch exists

### Task 5: Cleanup Only After Stable Use

**Files:**
- Reference: `modules/system/darwin/maintenance/nix-store.nix`

**Step 1: Wait for at least one stable day of normal use**

Expected: no emergency rollback, shell regressions, GUI regressions, or OpenClaw regressions are observed.

**Step 2: Remove old generations only after soak**

Run:

```bash
sudo darwin-rebuild --list-generations
sudo nix-collect-garbage -d
```

Expected: old generations are removed only after the current generation has proved stable enough that rollback is no longer likely.
