# Nix comment and config style

Conventions for Nix in this repo; matches pre-commit (nixfmt, prettier).

## 1. Format

- Indent: 2 spaces. Line width: 100 (nixfmt).
- Attributes: `key = value;` with semicolon.
- One blank line after `{ ... }:` before `{` or `let`.

```nix
# Preferred
{ pkgs, ... }:

{
  foo = true;
}

# Avoid: no blank after signature
{ pkgs, ... }:
{
  foo = true;
}
```

## 2. Comments

### 2.1 File header

- Multi-line `#` at top: first line = brief summary; optional detail lines.
- One blank line between header and `{ ... }:`.

```nix
# PostgreSQL 16: Nix package, data dir, and launchd service
{ config, pkgs, lib, myvars, ... }:

let
  ...
```

### 2.2 Section dividers

- Only in long multi-section files (outputs, per-arch entrypoints, option/config modules).
- Format: `# ===...===` (~80 chars), title line above and below.

```nix
  # =====================================================================================
  # Project-level extensions
  # =====================================================================================
```

### 2.3 Inline and block

- Inline: `key = value; # comment` (space before `#`). Block: standalone `#` line above block, same indent.
- Prefer English; keep terms consistent.

## 3. let / in

- Short let: no blank before `in`. Long/many bindings: blank between `let` and `in`. Optional blank after `in` before `{`.

## 4. Other

- Lists/attrsets: nixfmt; trailing comma optional. File ends with one newline.
