#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

printf '[deprecated] %s\n' 'scripts/build-nixos-iso-remote.sh is deprecated. Use scripts/iso/build-remote.sh instead.' >&2
printf '[deprecated] %s\n' 'Defaulting to --flake-subpath nixos-installer for compatibility.' >&2

exec "${SCRIPT_DIR}/iso/build-remote.sh" --flake-subpath "nixos-installer" "$@"
