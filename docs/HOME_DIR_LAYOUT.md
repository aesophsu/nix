# ~/ layout

Purpose of top-level dirs under `~/` and how they’re organized.

## 1. By purpose

### System / runtime (don’t touch)

| Dir/file | Purpose | Action |
|----------|---------|--------|
| `.cache/` | App caches (bat, nix eval-cache) | Keep |
| `.config/` | App config (mostly Home Manager) | Keep |
| `.local/` | Local state (nix profile, etc.) | Keep |
| `.nix-defexpr` / `.nix-profile` | Nix expr and profile links | Keep |
| `Library/`, `Applications/` | macOS / HM apps | Keep |
| `Desktop/` … `Public/` | macOS user dirs | Keep |

### Secrets (don’t touch)

| Dir | Purpose |
|-----|---------|
| `.ssh/` | SSH keys and config |
| `.secrets/` | Private keys / secrets |

### App data (keep as needed)

| Dir | Purpose |
|-----|---------|
| `.codex/`, `.cursor/` | AI/IDE data |
| `.openclaw/` | OpenClaw runtime |
| `Zotero/` | Zotero library |

### Config / code (under ~/Code)

| Path | Purpose |
|------|---------|
| **~/Code/nix** | Nix config (nix-darwin + HM); darwin-rebuild entry |
| **~/Code/claw** | Path deps (flake-utils, nix-openclaw, nix-steipete-tools) |

Config and code live under **~/Code** for backup and clarity.

---

## 2. How it was done

- Create `~/Code`; move former `~/nix` → `~/Code/nix`, `~/claw` → `~/Code/claw`.
- In nix: path inputs → `path:/Users/sue/Code/claw/<name>`; docs updated to ~/Code/nix, ~/Code/claw.
- Run darwin-rebuild from `~/Code/nix`.

---

## 3. Notes

- Home Manager `home.homeDirectory` is `/Users/<username>` (vars); independent of repo path.
- Nix only needs path in flake.nix; ensure `~/Code/claw` subdirs exist.
