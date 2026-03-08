# Darwin Structure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Standardize Darwin-specific module organization by replacing auto-discovery in the user Darwin tree with explicit import manifests and aligned entrypoints.

**Architecture:** Keep the existing `apps` / `profiles` / `services` / `system` layout, but make assembly explicit everywhere. Each directory entrypoint should either define local bootstrap settings or delegate to a `.imports.nix` manifest with an intentional order.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager

---

### Task 1: Add an explicit manifest for `user/darwin/`

**Files:**
- Create: `user/darwin/.imports.nix`
- Modify: `user/darwin/default.nix`
- Verify: `user/darwin/README.md`

**Step 1: Inspect current Darwin user entrypoint**

Run: `sed -n '1,200p' user/darwin/default.nix`
Expected: it defines `home.homeDirectory`, `xdg.enable`, and uses `mylib.discoverImports`.

**Step 2: Create the failing structural expectation**

Write down the intended ordered imports for the Darwin user layer:

```nix
[
  ../common/core
  ../common/home.nix
  ./ghostty.nix
  ./apps
  ./profiles
  ./services
]
```

Expected: this list covers everything that was previously discovered implicitly in the Darwin user layer.

**Step 3: Write the minimal implementation**

Create `user/darwin/.imports.nix` with the explicit import list.

Update `user/darwin/default.nix` so it keeps only the bootstrap settings and imports:

```nix
{
  home.homeDirectory = ...;
  xdg.enable = true;
  imports = import ./.imports.nix;
}
```

**Step 4: Run a targeted inspection**

Run: `sed -n '1,200p' user/darwin/.imports.nix`
Expected: explicit manifest is visible and ordered.

**Step 5: Commit**

```bash
git add user/darwin/default.nix user/darwin/.imports.nix
git commit -m "refactor: make darwin user imports explicit"
```

### Task 2: Convert `user/darwin/profiles/` to explicit imports

**Files:**
- Create: `user/darwin/profiles/.imports.nix`
- Modify: `user/darwin/profiles/default.nix`
- Verify: `user/darwin/profiles/shell.nix`

**Step 1: Inspect the current profile entrypoint**

Run: `sed -n '1,200p' user/darwin/profiles/default.nix`
Expected: it uses `mylib.discoverImports`.

**Step 2: Write the failing structural expectation**

Start with the current explicit profile set:

```nix
[
  ./shell.nix
]
```

Expected: the profile directory contents are now controlled solely by this manifest.

**Step 3: Write the minimal implementation**

Create `user/darwin/profiles/.imports.nix` with the current profile list.

Replace auto-discovery in `user/darwin/profiles/default.nix` with:

```nix
{
  imports = import ./.imports.nix;
}
```

**Step 4: Run a targeted inspection**

Run: `sed -n '1,200p' user/darwin/profiles/.imports.nix`
Expected: `shell.nix` is listed explicitly.

**Step 5: Commit**

```bash
git add user/darwin/profiles/default.nix user/darwin/profiles/.imports.nix
git commit -m "refactor: make darwin profile imports explicit"
```

### Task 3: Convert `user/darwin/services/` to explicit imports

**Files:**
- Create: `user/darwin/services/.imports.nix`
- Modify: `user/darwin/services/default.nix`
- Verify: `user/darwin/services/mihomo/default.nix`
- Verify: `user/darwin/services/postgresql/default.nix`

**Step 1: Inspect the current services entrypoint**

Run: `sed -n '1,200p' user/darwin/services/default.nix`
Expected: it uses `mylib.discoverImports`.

**Step 2: Write the failing structural expectation**

Define the explicit current service list:

```nix
[
  ./mihomo
  ./postgresql
]
```

Expected: both existing service directories are listed directly and in the intended order.

**Step 3: Write the minimal implementation**

Create `user/darwin/services/.imports.nix` with the current service list.

Replace auto-discovery in `user/darwin/services/default.nix` with:

```nix
{
  imports = import ./.imports.nix;
}
```

**Step 4: Run a targeted inspection**

Run: `sed -n '1,200p' user/darwin/services/.imports.nix`
Expected: `mihomo` and `postgresql` are listed explicitly.

**Step 5: Commit**

```bash
git add user/darwin/services/default.nix user/darwin/services/.imports.nix
git commit -m "refactor: make darwin service imports explicit"
```

### Task 4: Align `user/darwin/apps/` with the same pattern

**Files:**
- Create: `user/darwin/apps/.imports.nix`
- Modify: `user/darwin/apps/default.nix`

**Step 1: Inspect the current apps entrypoint**

Run: `sed -n '1,200p' user/darwin/apps/default.nix`
Expected: it is currently empty or effectively a placeholder.

**Step 2: Write the failing structural expectation**

If there are no app modules yet, define an empty manifest:

```nix
[ ]
```

Expected: the directory still participates in the same explicit-entry convention.

**Step 3: Write the minimal implementation**

Create `user/darwin/apps/.imports.nix` as an empty list or with current app modules if any appear during implementation.

Update `user/darwin/apps/default.nix` to:

```nix
{
  imports = import ./.imports.nix;
}
```

**Step 4: Run a targeted inspection**

Run: `sed -n '1,200p' user/darwin/apps/.imports.nix`
Expected: manifest exists, even if empty.

**Step 5: Commit**

```bash
git add user/darwin/apps/default.nix user/darwin/apps/.imports.nix
git commit -m "refactor: align darwin app entrypoints"
```

### Task 5: Update Darwin user documentation

**Files:**
- Modify: `user/darwin/README.md`

**Step 1: Inspect the current README**

Run: `sed -n '1,240p' user/darwin/README.md`
Expected: it references top-level module auto-scanning.

**Step 2: Write the failing documentation expectation**

Replace scanning-oriented wording with explicit-manifest wording that explains:

- `default.nix` bootstraps the layer
- `.imports.nix` defines load order
- adding a module requires editing the matching manifest

**Step 3: Write the minimal implementation**

Update the README so the documented structure matches the actual file layout after the refactor.

**Step 4: Run a targeted inspection**

Run: `rg -n "自动扫描|discoverImports" user/darwin/README.md`
Expected: no matches that describe the Darwin user layer as auto-discovered.

**Step 5: Commit**

```bash
git add user/darwin/README.md
git commit -m "docs: document explicit darwin module manifests"
```

### Task 6: Verify evaluation and structural consistency

**Files:**
- Verify: `user/darwin/default.nix`
- Verify: `user/darwin/apps/default.nix`
- Verify: `user/darwin/profiles/default.nix`
- Verify: `user/darwin/services/default.nix`
- Verify: `outputs/default.nix`

**Step 1: Run targeted grep for removed discovery usage**

Run: `rg -n "discoverImports" user/darwin`
Expected: no matches in the Darwin user entrypoints that were migrated.

**Step 2: Run repository checks**

Run: `nix flake check`
Expected: Darwin eval and configured checks pass.

**Step 3: Run focused file inspections**

Run: `sed -n '1,200p' user/darwin/default.nix`
Expected: no discovery logic, only bootstrap settings plus explicit imports.

Run: `sed -n '1,200p' user/darwin/profiles/default.nix`
Expected: imports only from `./.imports.nix`.

Run: `sed -n '1,200p' user/darwin/services/default.nix`
Expected: imports only from `./.imports.nix`.

**Step 4: Confirm unchanged module coverage**

Run: `find user/darwin -maxdepth 3 \\( -name '*.nix' -o -name '.imports.nix' \\) | sort`
Expected: manifests and modules are all present, with Ghostty, shell, Mihomo, and PostgreSQL still wired by explicit imports.

**Step 5: Commit**

```bash
git add user/darwin
git commit -m "refactor: standardize darwin module entrypoints"
```
