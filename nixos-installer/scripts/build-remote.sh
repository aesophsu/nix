#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

exec "${REPO_ROOT}/scripts/iso/build-remote.sh" --flake-subpath "nixos-installer" "$@"
