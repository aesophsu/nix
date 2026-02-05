# PostgreSQL 16

Nixpkgs package; data dir, initdb, launchd in `home/darwin/postgresql/default.nix`. Start on login. Uses Nix cache (avoids Homebrew ghcr.io issues).

## Paths

| Item | Path |
|------|------|
| Data | `~/.local/share/postgresql/16/` |
| Log | `~/.local/share/postgresql/16.log` |
| Config | `~/.local/share/postgresql/16/postgresql.conf` |

## Service

| Action | Command |
|--------|---------|
| Start | `launchctl kickstart -k gui/$(id -u)/org.nix.postgresql` |
| Stop | `launchctl bootout gui/$(id -u)/org.nix.postgresql` |
| Status | `launchctl print gui/$(id -u)/org.nix.postgresql` |
| Log | `tail -f ~/.local/share/postgresql/16.log` |

First deploy runs initdb if data dir missing. Manual initdb: `initdb -D ~/.local/share/postgresql/16 -E UTF8`.

**Usage**: `psql postgres`, `createdb myapp`, `createuser -s $USER`. Conn: `postgres://sue@localhost:5432/postgres`.
