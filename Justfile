set shell := ["nu", "-c"]
utils_nu := absolute_path("utils.nu")

# List available commands
default:
    @just --list

# Run root + installer eval checks
check:
    nix flake check --no-build --all-systems
    nix flake check --no-build ./nixos-installer

# Darwin checks only (root flake)
check-darwin:
    nix build --no-link .#checks.aarch64-darwin.smoke-eval
    nix build --no-link .#checks.aarch64-darwin.docs-sync
    nix build --no-link .#checks.aarch64-darwin.pre-commit

# Linux checks (root flake + installer eval)
check-linux:
    nix build --no-link .#checks.x86_64-linux.smoke-eval
    nix build --no-link .#checks.x86_64-linux.docs-sync
    nix build --no-link .#checks.x86_64-linux.pre-commit
    nix flake check --no-build ./nixos-installer

# Regenerate and verify generated docs

docs:
    python3 scripts/docs/generate.py --write
    python3 scripts/docs/generate.py --check

# Format repository files via flake formatter
fmt:
    nix fmt

# Update all flake inputs
up:
    nix flake update --commit-lock-file

# Update one flake input
upp input:
    nix flake update {{input}} --commit-lock-file

# Darwin local deploy (switch/build/test)
darwin-local mode="switch":
    #!/usr/bin/env nu
    use {{utils_nu}} *
    let h = (host-name)
    log $"darwin-rebuild ($mode) for ($h)"
    ^darwin-rebuild $mode --flake $".#($h)"

# Darwin rollback
darwin-rollback:
    darwin-rebuild switch --rollback

# Eval shaka toplevel drvPath (no switch)
shaka-build:
    nix eval --raw .#nixosConfigurations.shaka.config.system.build.toplevel.drvPath

# Show installer manual doc
shaka-install-doc:
    sed -n '1,160p' nixos-installer/README.md

# Build installer ISO locally via bootstrap subflake
iso-build-local:
    nix build ./nixos-installer#packages.x86_64-linux.shaka-manual-installer-iso

# Remote ISO build (canonical script)
iso-build-remote host remote_dir alias="shaka-manual-installer-iso":
    #!/usr/bin/env nu
    use {{utils_nu}} *
    assert-non-empty "host" $host
    assert-non-empty "remote_dir" $remote_dir
    git-dirty-warning
    ^scripts/iso/build-remote.sh --host $host --remote-dir $remote_dir --flake-subpath nixos-installer --iso $alias

# Remote ISO build dry-run
iso-dry-run host remote_dir alias="shaka-manual-installer-iso":
    #!/usr/bin/env nu
    use {{utils_nu}} *
    assert-non-empty "host" $host
    assert-non-empty "remote_dir" $remote_dir
    ^scripts/iso/build-remote.sh --dry-run --host $host --remote-dir $remote_dir --flake-subpath nixos-installer --iso $alias

# Scan tracked content for secret-like strings
secret-audit:
    scripts/security/audit-secrets.sh

# Show secrets source mode (private/local/disabled)
secret-status:
    nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); in import ./secrets/source.nix { inputs = flake.inputs; }'

# Basic agenix environment checks for this repo setup
secret-doctor:
    #!/usr/bin/env nu
    use {{utils_nu}} *
    log "Checking agenix/rage CLI availability (optional but recommended)"
    ^sh -lc 'command -v agenix >/dev/null && agenix --help >/dev/null && echo agenix:ok || echo agenix:missing'
    ^sh -lc 'command -v rage >/dev/null && echo rage:ok || echo rage:missing'
    log "Secrets source mode"
    ^just secret-status
    log "Tracked content audit"
    ^scripts/security/audit-secrets.sh
    log "Expected local fallback directory"
    ^ls -la secrets/local

# Print rekey guidance for private secrets repo (no action in public repo)
secret-rekey-help:
    sed -n '1,220p' secrets/README.md
