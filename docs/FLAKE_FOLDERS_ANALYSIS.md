# Flake folders: roles and layout

## 1. Four folders

| Folder | Role | Contents | Used by |
|--------|------|----------|---------|
| **flake-utils** | Upstream (numtide) | Nix helpers: eachSystem, simpleFlake, filterPackages, flattenTree | nix (path), nix-openclaw |
| **nix** | This config | nix-darwin + home-manager: outputs, modules, home, hosts, lib, vars, overlays, misc, docs | Local darwin-rebuild |
| **nix-openclaw** | Upstream (openclaw) | OpenClaw Nix: packages, overlay, HM/darwin modules, checks, scripts, templates | nix (path); uses flake-utils, home-manager, nix-steipete-tools |
| **nix-steipete-tools** | Upstream (openclaw) | steipete tools Nix: summarize, gogcli, bird, peekaboo, oracle; each has tools/<name>/flake.nix | nix (path), nix-openclaw |

---

## 2. Dependencies

```
                    ┌─────────────────┐
                    │   flake-utils   │  lib only
                    └────────┬────────┘
                             │
     ┌───────────────────────┼───────────────────────┐
     │                       │                       │
     ▼                       ▼                       │
┌─────────┐           ┌──────────────┐                │
│   nix   │◄──path───►│ nix-openclaw │◄───────────────┘
│ (config)│           │ (openclaw)   │
└────┬────┘           └──────┬───────┘
     │                        │
     │ path                   │ input
     ▼                        ▼
┌─────────────────────┐  ┌─────────────────────┐
│ nix-steipete-tools  │◄─┤ (steipete pkgs)    │
└─────────────────────┘  └─────────────────────┘
```

- **nix**: Path refs `~/Code/claw/<name>` so daemon doesn’t need GitHub at rebuild.
- **nix-openclaw**: Gets flake-utils, home-manager, nix-steipete-tools via nix flake `follows`.

---

## 3. What you can change

### Only nix is under your control

Upstream repos: clone + path ref; don’t change their layout. Optimize inside nix: how you reference them and how OpenClaw is documented.

### documents/ vs nix-openclaw template

- nix: `home/darwin/openclaw/documents/` (AGENTS.md, SOUL.md, TOOLS.md)
- nix-openclaw: `templates/agent-first/documents/` (same content)

Options: (A) Keep copy in nix, note “sync with agent-first manually.” (B) Reference template path from Nix (`openclawDocumentsPath` in genSpecialArgs, `documents = openclawDocumentsPath` in openclaw default.nix); single source, requires path to nix-openclaw.

### OpenClaw in three places (document it)

- **outputs/default.nix**: genSpecialArgs → lib/openclaw-package.nix → openclawPackageNoOracle; overlay injected in **outputs/aarch64-darwin/src/stella.nix**.
- **lib/openclaw-package.nix**: Calls nix-openclaw packages, excludes oracle, PATH-safe wrapper.
- **modules/darwin/openclaw.nix**: Placeholder; overlay is in stella.nix.

Document in OPENCLAW_SETUP or lib/README: why path refs, where overlay is injected, who provides the no-oracle package, and that home entry is `home/darwin/openclaw/default.nix`.

### Fewer folders?

Four folders: one tool lib, two upstream, one config. Complexity is from the ref chain and OpenClaw split across 3 files, not from folder count. To avoid local clones: switch to GitHub URL + rev, run `nix flake update` once with proxy, then rely on cache (misses need GitHub). For offline rebuild, keep path inputs.

---

## 4. Recommended (nix only)

1. **Docs**: Add “OpenClaw integration” to OPENCLAW_SETUP or lib/README (section 3 above).
2. **documents**: Either keep copy + “sync with agent-first,” or use openclawDocumentsPath and remove copy.
3. **No change** to flake-utils / nix-openclaw / nix-steipete-tools layout. Optionally list path deps and purpose in README/DEPLOYMENT.

---

## 5. Summary

| Question | Answer |
|----------|--------|
| Merge four into one? | No. Different roles. |
| Less confusion? | Yes. Centralize OpenClaw docs and optionally documents source. |
| Further cleanup? | Only inside nix: docs, documents; leave upstream as-is. |

---

## 6. Path deps under ~/Code/claw (done)

```
~/Code/
├── nix/           # config; darwin-rebuild entry
└── claw/
    ├── README.md  # clone/migrate commands
    ├── flake-utils/
    ├── nix-openclaw/
    └── nix-steipete-tools/
```

flake.nix uses `path:/Users/sue/Code/claw/<name>`. First clone on a new machine: run commands in `~/Code/claw/README.md`.
