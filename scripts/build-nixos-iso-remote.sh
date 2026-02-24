#!/usr/bin/env bash
#
# Upload current working tree to a remote Linux host, build a NixOS installer ISO there,
# then download the ISO back to this machine.
#
# See docs/NIXOS_ISO_REMOTE_BUILD.md for details.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ENV_LOCAL="${SCRIPT_DIR}/build-nixos-iso-remote.env.local"

# Fixed defaults (CLI flags override env overrides these defaults)
DEFAULT_ISO_ALIAS="shaka-installer-iso"
DEFAULT_LOCAL_OUT_DIR="${REPO_ROOT}/archive/iso-out"
DEFAULT_FLAKE_SUBPATH="."

if [[ -f "${ENV_LOCAL}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_LOCAL}"
fi

REMOTE_HOST="${NIX_ISO_REMOTE_HOST:-}"
REMOTE_DIR="${NIX_ISO_REMOTE_DIR:-}"
ISO_ALIAS="${NIX_ISO_ALIAS:-${DEFAULT_ISO_ALIAS}}"
LOCAL_OUT_DIR="${NIX_ISO_LOCAL_OUT_DIR:-${DEFAULT_LOCAL_OUT_DIR}}"
FLAKE_SUBPATH="${NIX_ISO_FLAKE_SUBPATH:-${DEFAULT_FLAKE_SUBPATH}}"
NIX_ISO_SSH_OPTS="${NIX_ISO_SSH_OPTS:-}"
KEEP_REMOTE="${NIX_ISO_KEEP_REMOTE:-0}"

DRY_RUN=0
VERBOSE=0

CURRENT_STAGE="init"
RUN_ID=""
REMOTE_RUN_DIR=""
REMOTE_BUILD_DIR=""
REMOTE_STORE_PATH=""
LOCAL_ISO_PATH=""

usage() {
  cat <<'EOF'
Usage:
  scripts/build-nixos-iso-remote.sh --host <ssh-host> --remote-dir <path> [options]

Required (flag or env):
  --host <ssh-host>         Remote Linux SSH host (or SSH config alias)
  --remote-dir <path>       Remote workspace root directory

Options:
  --iso <alias>             Flake ISO package alias (default: shaka-installer-iso)
  --local-out-dir <path>    Local output dir for downloaded ISOs (default: archive/iso-out)
  --flake-subpath <path>    Relative subpath under uploaded repo to build from (default: .)
  --keep-remote             Keep remote run directory after success
  --dry-run                 Print planned commands only
  --verbose                 Print extra logs
  --help                    Show this help

Env vars (optional):
  NIX_ISO_REMOTE_HOST
  NIX_ISO_REMOTE_DIR
  NIX_ISO_ALIAS
  NIX_ISO_LOCAL_OUT_DIR
  NIX_ISO_FLAKE_SUBPATH
  NIX_ISO_SSH_OPTS
  NIX_ISO_KEEP_REMOTE=1
EOF
}

log() {
  printf '[iso-remote] %s\n' "$*"
}

warn() {
  printf '[iso-remote][warn] %s\n' "$*" >&2
}

die() {
  printf '[iso-remote][error] %s\n' "$*" >&2
  exit 1
}

debug() {
  if [[ "${VERBOSE}" == "1" ]]; then
    log "$*"
  fi
}

quote_sh() {
  printf '%q' "$1"
}

on_error() {
  local exit_code=$?
  printf '[iso-remote][error] Stage failed: %s (exit=%s)\n' "${CURRENT_STAGE}" "${exit_code}" >&2
  if [[ -n "${REMOTE_RUN_DIR}" ]]; then
    printf '[iso-remote][error] Remote run dir kept for debugging: %s\n' "${REMOTE_RUN_DIR}" >&2
  fi
  exit "${exit_code}"
}
trap on_error ERR

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      [[ $# -ge 2 ]] || die "--host requires a value"
      REMOTE_HOST="$2"
      shift 2
      ;;
    --remote-dir)
      [[ $# -ge 2 ]] || die "--remote-dir requires a value"
      REMOTE_DIR="$2"
      shift 2
      ;;
    --iso)
      [[ $# -ge 2 ]] || die "--iso requires a value"
      ISO_ALIAS="$2"
      shift 2
      ;;
    --local-out-dir)
      [[ $# -ge 2 ]] || die "--local-out-dir requires a value"
      LOCAL_OUT_DIR="$2"
      shift 2
      ;;
    --flake-subpath)
      [[ $# -ge 2 ]] || die "--flake-subpath requires a value"
      FLAKE_SUBPATH="$2"
      shift 2
      ;;
    --keep-remote)
      KEEP_REMOTE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[[ -n "${REMOTE_HOST}" ]] || die "Missing remote host (use --host or NIX_ISO_REMOTE_HOST)"
[[ -n "${REMOTE_DIR}" ]] || die "Missing remote dir (use --remote-dir or NIX_ISO_REMOTE_DIR)"

if [[ "${FLAKE_SUBPATH}" = /* ]]; then
  die "--flake-subpath must be relative, got absolute path: ${FLAKE_SUBPATH}"
fi

for cmd in git nix ssh rsync; do
  command -v "${cmd}" >/dev/null 2>&1 || die "Missing local command: ${cmd}"
done

if ! git -C "${REPO_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  die "Repository root is not a git work tree: ${REPO_ROOT}"
fi

CURRENT_STAGE="preflight-local"
COMMIT_SHORT="$(git -C "${REPO_ROOT}" rev-parse --short HEAD 2>/dev/null || true)"
if [[ -z "${COMMIT_SHORT}" ]]; then
  COMMIT_SHORT="no-git"
fi

DIRTY_STATE="clean"
if [[ -n "$(git -C "${REPO_ROOT}" status --porcelain)" ]]; then
  DIRTY_STATE="dirty"
  warn "Working tree is dirty; uploading current working tree (not just committed files)."
fi

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_ID="${TIMESTAMP}-${COMMIT_SHORT}-${DIRTY_STATE}"
REMOTE_RUN_DIR="${REMOTE_DIR%/}/runs/${RUN_ID}"
REMOTE_BUILD_DIR="${REMOTE_RUN_DIR}/${FLAKE_SUBPATH}"
LOCAL_ISO_PATH="${LOCAL_OUT_DIR%/}/${ISO_ALIAS}-${RUN_ID}.iso"

CURRENT_STAGE="validate-iso-alias"
if ! nix eval --raw ".#packages.x86_64-linux.${ISO_ALIAS}.outPath" >/dev/null 2>&1; then
  AVAILABLE_ALIASES="$(nix eval --json '.#packages.x86_64-linux' --apply 'x: builtins.attrNames x' 2>/dev/null || true)"
  die "Invalid ISO alias '${ISO_ALIAS}'. Available aliases: ${AVAILABLE_ALIASES:-<unknown>}"
fi

read -r -a SSH_OPTS_ARR <<< "${NIX_ISO_SSH_OPTS}"
SSH_BASE=(ssh "${SSH_OPTS_ARR[@]}")
RSYNC_RSH="ssh"
if [[ -n "${NIX_ISO_SSH_OPTS}" ]]; then
  RSYNC_RSH="ssh ${NIX_ISO_SSH_OPTS}"
fi

ssh_run() {
  "${SSH_BASE[@]}" "${REMOTE_HOST}" "$@"
}

run_or_echo() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$@"
  fi
}

print_cmd_array() {
  local prefix="$1"
  shift
  printf '%s' "${prefix}"
  if [[ $# -gt 0 ]]; then
    printf ' %q' "$@"
  fi
  printf '\n'
}

log "Repo root: ${REPO_ROOT}"
log "Remote host: ${REMOTE_HOST}"
log "Remote dir: ${REMOTE_DIR}"
log "Run ID: ${RUN_ID}"
log "ISO alias: ${ISO_ALIAS}"
log "Commit: ${COMMIT_SHORT} (${DIRTY_STATE})"
log "Local output path: ${LOCAL_ISO_PATH}"
debug "flake-subpath=${FLAKE_SUBPATH}"

CURRENT_STAGE="preflight-remote"
REMOTE_PREFLIGHT_CMD="command -v bash >/dev/null && command -v rsync >/dev/null && command -v nix >/dev/null"
if [[ "${DRY_RUN}" == "1" ]]; then
  printf '[dry-run] ssh %s bash -lc %q\n' "${REMOTE_HOST}" "${REMOTE_PREFLIGHT_CMD}"
else
  ssh_run bash -lc "${REMOTE_PREFLIGHT_CMD}" >/dev/null
fi

RSYNC_EXCLUDES=(
  ".git/"
  ".direnv/"
  "result"
  "result-*"
  "archive/iso-out/"
  "scripts/docs/__pycache__/"
  ".DS_Store"
)

CURRENT_STAGE="upload"
RSYNC_UPLOAD_CMD=(
  rsync -a
  -e "${RSYNC_RSH}"
)
for pat in "${RSYNC_EXCLUDES[@]}"; do
  RSYNC_UPLOAD_CMD+=(--exclude "${pat}")
done
RSYNC_UPLOAD_CMD+=(
  "${REPO_ROOT}/"
  "${REMOTE_HOST}:${REMOTE_RUN_DIR}/"
)

if [[ "${DRY_RUN}" == "1" ]]; then
  print_cmd_array "[dry-run]" "${RSYNC_UPLOAD_CMD[@]}"
else
  ssh_run mkdir -p "${REMOTE_RUN_DIR}"
  "${RSYNC_UPLOAD_CMD[@]}"
fi

CURRENT_STAGE="build"
REMOTE_BUILD_CMD=$(
  cat <<EOF
set -euo pipefail
cd $(quote_sh "${REMOTE_BUILD_DIR}")
nix build --print-out-paths ".#packages.x86_64-linux.${ISO_ALIAS}"
EOF
)

if [[ "${DRY_RUN}" == "1" ]]; then
  printf '[dry-run] ssh %s bash -lc %q\n' "${REMOTE_HOST}" "${REMOTE_BUILD_CMD}"
  REMOTE_STORE_PATH="/nix/store/<remote-built-iso>.iso"
else
  REMOTE_STORE_PATH="$(ssh_run bash -lc "${REMOTE_BUILD_CMD}")"
  REMOTE_STORE_PATH="${REMOTE_STORE_PATH//$'\r'/}"
  REMOTE_STORE_PATH="${REMOTE_STORE_PATH%%$'\n'*}"
fi

[[ -n "${REMOTE_STORE_PATH}" ]] || die "Remote build did not return an output path"
case "${REMOTE_STORE_PATH}" in
  *.iso) ;;
  *)
    die "Remote build output does not look like an ISO path: ${REMOTE_STORE_PATH}"
    ;;
esac

CURRENT_STAGE="download"
RSYNC_DOWNLOAD_CMD=(
  rsync -avP
  -e "${RSYNC_RSH}"
  "${REMOTE_HOST}:${REMOTE_STORE_PATH}"
  "${LOCAL_ISO_PATH}"
)

if [[ "${DRY_RUN}" == "1" ]]; then
  printf '[dry-run] mkdir -p %q\n' "${LOCAL_OUT_DIR}"
  print_cmd_array "[dry-run]" "${RSYNC_DOWNLOAD_CMD[@]}"
else
  mkdir -p "${LOCAL_OUT_DIR}"
  "${RSYNC_DOWNLOAD_CMD[@]}"
fi

CURRENT_STAGE="post-download"
LOCAL_SHA256=""
LOCAL_SIZE=""
if [[ "${DRY_RUN}" == "1" ]]; then
  LOCAL_SHA256="<dry-run>"
  LOCAL_SIZE="<dry-run>"
else
  if command -v shasum >/dev/null 2>&1; then
    LOCAL_SHA256="$(shasum -a 256 "${LOCAL_ISO_PATH}" | awk '{print $1}')"
  elif command -v sha256sum >/dev/null 2>&1; then
    LOCAL_SHA256="$(sha256sum "${LOCAL_ISO_PATH}" | awk '{print $1}')"
  else
    LOCAL_SHA256="<sha256 unavailable>"
  fi
  LOCAL_SIZE="$(wc -c < "${LOCAL_ISO_PATH}" | tr -d ' ')"
fi

CURRENT_STAGE="cleanup"
if [[ "${KEEP_REMOTE}" != "1" ]]; then
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '[dry-run] ssh %s rm -rf %q\n' "${REMOTE_HOST}" "${REMOTE_RUN_DIR}"
  else
    ssh_run rm -rf "${REMOTE_RUN_DIR}"
    REMOTE_RUN_DIR=""
  fi
else
  log "Keeping remote run dir: ${REMOTE_RUN_DIR}"
fi

CURRENT_STAGE="done"
log "Remote store path: ${REMOTE_STORE_PATH}"
log "Local ISO path: ${LOCAL_ISO_PATH}"
log "Local ISO size(bytes): ${LOCAL_SIZE}"
log "Local ISO sha256: ${LOCAL_SHA256}"
log "Done."
