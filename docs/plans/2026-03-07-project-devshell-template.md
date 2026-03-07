# Project DevShell Template Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Establish a machine-wide workflow where global base tools stay in Home Manager, each project uses its own `flake.nix` + `.envrc`, and `direnv` auto-activates project shells with reusable templates and helper commands.

**Architecture:** Keep global shell integration and helper scripts in the existing Home Manager modules, while adding project template files under this repo for copy-based bootstrap. Tighten the boundary by documenting project-local toolchains as the default and reducing reliance on globally installed language runtimes where practical.

**Tech Stack:** nix-darwin, Home Manager, Nix flakes, direnv, nix-direnv, shell scripts

---

### Task 1: Inspect current shell and package wiring

**Files:**
- Verify: `user/common/core/packages.nix`
- Verify: `user/common/core/shells/default.nix`
- Verify: `user/darwin/profiles/shell.nix`
- Verify: `user/common/core/tooling/toolchain.nix`

**Step 1: Read the current global package and shell modules**

Run: `sed -n '1,220p' user/common/core/packages.nix`
Expected: shows `direnv`/`nix-direnv` enabled and current base packages.

**Step 2: Read shell initialization modules**

Run: `sed -n '1,260p' user/common/core/shells/default.nix`
Expected: shows current bash/nushell setup and no explicit project bootstrap helpers yet.

**Step 3: Read login shell profile module**

Run: `sed -n '1,260p' user/darwin/profiles/shell.nix`
Expected: shows current zsh/bash init content where any shell hook additions must fit.

**Step 4: Confirm current global language toolchains**

Run: `sed -n '1,220p' user/common/core/tooling/toolchain.nix`
Expected: shows Python/Node and related packages currently installed globally.

**Step 5: Commit checkpoint**

```bash
git status --short
```

### Task 2: Add reusable devshell templates

**Files:**
- Create: `templates/devshell/base/flake.nix`
- Create: `templates/devshell/base/.envrc`
- Create: `templates/devshell/python/flake.nix`
- Create: `templates/devshell/python/.envrc`
- Create: `templates/devshell/node/flake.nix`
- Create: `templates/devshell/node/.envrc`

**Step 1: Write the failing expectation as manual acceptance criteria**

Expectation:
- `base` template exposes a minimal default dev shell
- `python` adds Python + uv + ruff
- `node` adds Node + Corepack-friendly setup

**Step 2: Create the base template**

Implement files so `templates/devshell/base/flake.nix` exports `devShells.aarch64-darwin.default` via `pkgs.mkShell`, and `templates/devshell/base/.envrc` contains only:

```bash
use flake
```

**Step 3: Create the Python template**

Implement `templates/devshell/python/flake.nix` with a default shell that includes:

```nix
[
  pkgs.python312
  pkgs.uv
  pkgs.ruff
]
```

and reuse the same `.envrc` shape.

**Step 4: Create the Node template**

Implement `templates/devshell/node/flake.nix` with a default shell that includes:

```nix
[
  pkgs.nodejs_22
]
```

plus a `shellHook` that runs:

```bash
corepack enable >/dev/null 2>&1 || true
```

and reuse the same `.envrc` shape.

**Step 5: Run evaluation checks for each template**

Run: `nix eval --file templates/devshell/base/flake.nix`
Expected: may not be suitable for flake files; if so, switch to copying into a temp dir and run `nix develop .#default --command true`.

**Step 6: Commit**

```bash
git add templates/devshell
git commit -m "feat: add reusable devshell templates"
```

### Task 3: Add helper scripts for project bootstrap and attach

**Files:**
- Create: `user/common/core/scripts/devshell-init`
- Create: `user/common/core/scripts/devshell-attach`
- Modify: `user/common/core/packages.nix`

**Step 1: Write the failing behavior checklist**

Expected behavior:
- `devshell-init <template>` copies missing files from `templates/devshell/<template>/`
- `devshell-attach <template>` is safe to run inside an existing cloned repo
- both commands refuse to overwrite `flake.nix` or `.envrc`
- both commands print `direnv allow` as the next step

**Step 2: Implement `devshell-init`**

Use a POSIX shell script that:
- resolves repo root
- validates template name
- ensures current directory is suitable
- copies only missing files
- exits non-zero on conflicts

**Step 3: Implement `devshell-attach`**

Use a similar script, but tuned for retrofitting existing repos:
- if only `.envrc` is missing and `flake.nix` exists, create just `.envrc`
- if both are missing, copy the selected template
- if `.envrc` exists already, fail without modifying anything

**Step 4: Expose scripts on PATH**

Modify `user/common/core/packages.nix` so these helper scripts are installed into the user environment, using the repository-local source path rather than duplicating script contents in Nix strings.

**Step 5: Run script smoke checks**

Run commands in temporary directories:

```bash
tmpdir="$(mktemp -d)"
cd "$tmpdir"
/path/to/devshell-init base
test -f flake.nix
test -f .envrc
```

Expected: files are created and existing-file conflicts return non-zero.

**Step 6: Commit**

```bash
git add user/common/core/packages.nix user/common/core/scripts/devshell-init user/common/core/scripts/devshell-attach
git commit -m "feat: add devshell bootstrap helpers"
```

### Task 4: Ensure shell integration is explicit and stable

**Files:**
- Modify: `user/common/core/shells/default.nix`
- Modify: `user/darwin/profiles/shell.nix`

**Step 1: Write the failing expectation**

Expectation:
- `direnv` activation is explicit in interactive shells
- existing PATH and npm prefix behavior still remains intact

**Step 2: Implement shell integration carefully**

Add only the minimal shell initialization needed so bash/zsh sessions consistently load `direnv` hooks without duplicating Home Manager behavior unnecessarily. Prefer the canonical Home Manager integration path if already available; otherwise add guarded hook lines such as:

```bash
eval "$(direnv hook zsh)"
```

or

```bash
eval "$(direnv hook bash)"
```

behind a command-exists guard.

**Step 3: Review for startup conflicts**

Run: `sed -n '1,260p' user/common/core/shells/default.nix`
Expected: no duplicate PATH exports or conflicting initialization order.

**Step 4: Commit**

```bash
git add user/common/core/shells/default.nix user/darwin/profiles/shell.nix
git commit -m "chore: make direnv shell integration explicit"
```

### Task 5: Tighten global vs project toolchain boundaries

**Files:**
- Modify: `user/common/core/tooling/toolchain.nix`
- Modify: `DEPLOYMENT.md`
- Modify: `user/darwin/README.md`

**Step 1: Write the failing policy statement**

Expected policy:
- global layer is for stable cross-project tools
- project templates are the default home for language/runtime tooling
- documentation states when to use templates vs global packages

**Step 2: Reduce or annotate global toolchains**

Edit `user/common/core/tooling/toolchain.nix` to either:
- remove Python/Node from the global layer, or
- keep only the minimum still justified by machine-wide workflows

Choose the smallest change that keeps current machine usability while making project-local templates the primary path.

**Step 3: Update deployment and usage docs**

Document:
- available templates
- `devshell-init` and `devshell-attach`
- `direnv allow` workflow
- the new boundary between global and project-local tooling

**Step 4: Commit**

```bash
git add user/common/core/tooling/toolchain.nix DEPLOYMENT.md user/darwin/README.md
git commit -m "docs: define project-local devshell workflow"
```

### Task 6: Verify the full workflow before completion

**Files:**
- Verify: `flake.nix`
- Verify: `templates/devshell/base/flake.nix`
- Verify: `templates/devshell/python/flake.nix`
- Verify: `templates/devshell/node/flake.nix`

**Step 1: Run Home Manager / flake evaluation**

Run:

```bash
nix flake check --no-build
```

Expected: evaluation succeeds without introducing new flake errors.

**Step 2: Test helper scripts in temporary directories**

Run separate smoke checks for:
- empty directory + `devshell-init base`
- repo-like directory with only `flake.nix` + `devshell-attach base`
- conflict case with existing `.envrc`

Expected: success on safe cases, non-zero exit on conflict case.

**Step 3: Test template activation path**

In a temporary directory seeded from each template, run:

```bash
direnv allow
nix develop .#default --command true
```

Expected: shell resolves successfully.

**Step 4: Review final diff**

Run:

```bash
git diff -- templates/devshell user/common/core user/darwin/README.md DEPLOYMENT.md
```

Expected: diff is limited to the intended workflow changes.

**Step 5: Final commit**

```bash
git add templates/devshell user/common/core user/darwin/README.md DEPLOYMENT.md
git commit -m "feat: add project devshell bootstrap workflow"
```
