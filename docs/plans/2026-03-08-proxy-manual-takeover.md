# Proxy Manual Takeover Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Keep `mihomo` running persistently after `darwin-rebuild switch` while removing automatic system proxy and shell proxy takeover from activation.

**Architecture:** Leave the existing Darwin module layout in place. Keep `user/darwin/services/mihomo/default.nix` focused on the long-lived proxy service, remove activation-time proxy side effects, and add explicit shell helper commands beside the existing manual system takeover tools.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager, launchd, macOS `networksetup`

---

### Task 1: Remove automatic system proxy takeover from activation

**Files:**
- Modify: `system/darwin/system/activation.nix`
- Test: `system/darwin/system/activation.nix`

**Step 1: Write the failing test**

Define the expected behavior change in the file diff itself: after this task, `activation.nix` must no longer reference `proxyPolicy`, `proxyTools.on`, or `proxyTools.off`.

**Step 2: Run test to verify it fails**

Run: `rg -n "proxyPolicy|proxy-on|proxy-off" system/darwin/system/activation.nix`
Expected: matches are present

**Step 3: Write minimal implementation**

Remove the proxy-related arguments and the activation snippet that toggles system proxy state during `switch`, leaving only the unrelated Software Update settings.

**Step 4: Run test to verify it passes**

Run: `rg -n "proxyPolicy|proxy-on|proxy-off" system/darwin/system/activation.nix`
Expected: no matches

**Step 5: Commit**

```bash
git add system/darwin/system/activation.nix
git commit -m "refactor: stop proxy takeover during darwin activation"
```

### Task 2: Remove automatic shell proxy env injection from mihomo service

**Files:**
- Modify: `user/darwin/services/mihomo/default.nix`
- Test: `user/darwin/services/mihomo/default.nix`

**Step 1: Write the failing test**

Define the expected behavior change in the file diff itself: the module should no longer assign `home.sessionVariables` from proxy env.

**Step 2: Run test to verify it fails**

Run: `rg -n "home\\.sessionVariables|proxyEnv|cliDefault" user/darwin/services/mihomo/default.nix`
Expected: matches are present

**Step 3: Write minimal implementation**

Delete the `proxyPolicy` and `proxyEnv` bindings that only support automatic shell injection, and remove the `home.sessionVariables` assignment. Keep package install, config link, and launchd agent intact.

**Step 4: Run test to verify it passes**

Run: `rg -n "home\\.sessionVariables|proxyEnv|cliDefault" user/darwin/services/mihomo/default.nix`
Expected: no matches

**Step 5: Commit**

```bash
git add user/darwin/services/mihomo/default.nix
git commit -m "refactor: keep mihomo service without shell proxy takeover"
```

### Task 3: Remove activation-time Homebrew proxy env injection

**Files:**
- Modify: `system/darwin/apps.nix`
- Test: `system/darwin/apps.nix`

**Step 1: Write the failing test**

Define the expected behavior change in the file diff itself: `system.activationScripts.homebrew` should no longer export proxy variables.

**Step 2: Run test to verify it fails**

Run: `rg -n "homebrew_mirror_env|homebrew_env_script|system\\.activationScripts|httpProxy|socksProxy" system/darwin/apps.nix`
Expected: matches are present

**Step 3: Write minimal implementation**

Remove the proxy-specific `let` bindings and the `system.activationScripts` block that exports env into Homebrew activation. Keep unrelated shell and Homebrew declarations unchanged.

**Step 4: Run test to verify it passes**

Run: `rg -n "homebrew_mirror_env|homebrew_env_script|system\\.activationScripts|httpProxy|socksProxy" system/darwin/apps.nix`
Expected: no matches

**Step 5: Commit**

```bash
git add system/darwin/apps.nix
git commit -m "refactor: stop injecting proxy env into homebrew activation"
```

### Task 4: Add explicit shell-level proxy helper commands

**Files:**
- Modify: `system/darwin/system/proxy-tools.nix`
- Test: `system/darwin/system/proxy-tools.nix`

**Step 1: Write the failing test**

Define the expected behavior change in the file diff itself: the module should expose `proxy-env-on`, `proxy-env-off`, and `proxy-env-status` in `environment.systemPackages`.

**Step 2: Run test to verify it fails**

Run: `rg -n "proxy-env-on|proxy-env-off|proxy-env-status" system/darwin/system/proxy-tools.nix`
Expected: no matches

**Step 3: Write minimal implementation**

Add three `pkgs.writeShellScriptBin` commands:

- `proxy-env-on` prints `export` lines for lower-case and upper-case proxy vars using the existing values from `myvars.networking.proxy.env`
- `proxy-env-off` prints `unset` lines for all proxy vars
- `proxy-env-status` prints the currently visible proxy env vars from the shell

Also add those scripts to `environment.systemPackages`.

**Step 4: Run test to verify it passes**

Run: `rg -n "proxy-env-on|proxy-env-off|proxy-env-status" system/darwin/system/proxy-tools.nix`
Expected: all three command names are present in definitions and package exports

**Step 5: Commit**

```bash
git add system/darwin/system/proxy-tools.nix
git commit -m "feat: add manual shell proxy helper commands"
```

### Task 5: Make proxy policy semantics safe by default

**Files:**
- Modify: `vars/networking/proxy.nix`
- Test: `vars/networking/proxy.nix`

**Step 1: Write the failing test**

Define the expected behavior change in the file diff itself: comments and defaults should no longer describe automatic takeover during activation or shell startup.

**Step 2: Run test to verify it fails**

Run: `sed -n '1,120p' vars/networking/proxy.nix`
Expected: comments still describe activation-time and shell-default automatic behavior

**Step 3: Write minimal implementation**

Update comments and, if retained, policy defaults so they reflect manual takeover semantics instead of automatic side effects. Keep shared proxy endpoint and `no_proxy` construction helpers unchanged.

**Step 4: Run test to verify it passes**

Run: `sed -n '1,120p' vars/networking/proxy.nix`
Expected: comments and defaults match the manual-takeover model

**Step 5: Commit**

```bash
git add vars/networking/proxy.nix
git commit -m "docs: align proxy policy semantics with manual takeover"
```

### Task 6: Update operator documentation

**Files:**
- Modify: `DEPLOYMENT.md`
- Modify: `user/darwin/README.md`
- Modify: `user/darwin/services/mihomo/README.md`
- Test: `DEPLOYMENT.md`

**Step 1: Write the failing test**

Define the expected behavior change in the file diff itself: docs must stop claiming that applying the configuration automatically enables proxy takeover.

**Step 2: Run test to verify it fails**

Run: `rg -n "default proxy|默认代理|system proxy|proxy-on|proxy-off|RunAtLoad|activation" DEPLOYMENT.md user/darwin/README.md user/darwin/services/mihomo/README.md`
Expected: existing wording still mixes service deployment with automatic takeover

**Step 3: Write minimal implementation**

Update the docs to state:

- `mihomo` is kept running persistently
- `switch` does not automatically change system proxy settings
- shell proxy env is opt-in
- `proxy-on`, `proxy-off`, `proxy-status`, `proxy-env-on`, and `proxy-env-off` are the intended manual control surface

**Step 4: Run test to verify it passes**

Run: `rg -n "手动|manual|proxy-env-on|proxy-env-off" DEPLOYMENT.md user/darwin/README.md user/darwin/services/mihomo/README.md`
Expected: updated docs clearly describe the manual takeover workflow

**Step 5: Commit**

```bash
git add DEPLOYMENT.md user/darwin/README.md user/darwin/services/mihomo/README.md
git commit -m "docs: document manual proxy takeover workflow"
```

### Task 7: Verify eval and user-visible behavior

**Files:**
- Verify: `system/darwin/system/activation.nix`
- Verify: `user/darwin/services/mihomo/default.nix`
- Verify: `system/darwin/apps.nix`
- Verify: `system/darwin/system/proxy-tools.nix`
- Verify: `vars/networking/proxy.nix`

**Step 1: Write the failing test**

Define the final acceptance checks before implementation claims:

- `switch` no longer changes system proxy state
- `mihomo` still runs after switch
- fresh shells have no injected proxy env
- manual commands still work

**Step 2: Run test to verify it fails**

Run: `nix eval .#darwinConfigurations.stella.system --show-trace >/tmp/proxy-manual-takeover-eval.txt`
Expected: eval succeeds only after all module references remain coherent

**Step 3: Write minimal implementation**

If eval exposes missing names or stale references, remove those references and keep the change surface minimal.

**Step 4: Run test to verify it passes**

Run: `nix eval .#darwinConfigurations.stella.system --show-trace >/tmp/proxy-manual-takeover-eval.txt`
Expected: command exits successfully

Run: `darwin-rebuild switch --flake .`
Expected: activation completes without toggling current system proxy state

Run: `launchctl print gui/$(id -u)/mihomo`
Expected: `mihomo` launchd agent is loaded

Run: `env | rg '^(http_proxy|https_proxy|all_proxy|HTTP_PROXY|HTTPS_PROXY|ALL_PROXY|NO_PROXY|no_proxy)='`
Expected: no output in a fresh shell unless the user manually enabled proxy env

Run: `proxy-status`
Expected: reports current system proxy state without having changed it during switch

Run: `eval "$(proxy-env-on)"`
Expected: current shell gains proxy vars

Run: `eval "$(proxy-env-off)"`
Expected: current shell proxy vars are removed

**Step 5: Commit**

```bash
git add system/darwin/system/activation.nix user/darwin/services/mihomo/default.nix system/darwin/apps.nix system/darwin/system/proxy-tools.nix vars/networking/proxy.nix DEPLOYMENT.md user/darwin/README.md user/darwin/services/mihomo/README.md
git commit -m "refactor: separate persistent proxy service from manual takeover"
```
