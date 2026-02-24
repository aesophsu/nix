#!/usr/bin/env bash
#
# Upload current working tree to a remote Linux host, build a NixOS manual installer ISO there,
# then download the ISO back to this machine.
#
# See docs/NIXOS_ISO_REMOTE_BUILD.md for details.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
ENV_LOCAL="${REPO_ROOT}/scripts/build-nixos-iso-remote.env.local"

# Fixed defaults (CLI flags override env overrides these defaults)
DEFAULT_ISO_ALIAS="shaka-manual-installer-iso"
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
SSH_CONNECT_TIMEOUT="${NIX_ISO_SSH_CONNECT_TIMEOUT:-15}"
REMOTE_BUILD_TIMEOUT="${NIX_ISO_REMOTE_BUILD_TIMEOUT:-7200}"
RSYNC_IO_TIMEOUT="${NIX_ISO_RSYNC_IO_TIMEOUT:-60}"
RSYNC_CONNECT_TIMEOUT="${NIX_ISO_RSYNC_CONNECT_TIMEOUT:-15}"
STAGE_LOG_TIMESTAMPS="${NIX_ISO_STAGE_LOG_TIMESTAMPS:-1}"

DRY_RUN=0
VERBOSE=0

CURRENT_STAGE="init"
RUN_ID=""
REMOTE_RUN_DIR=""
REMOTE_BUILD_DIR=""
REMOTE_STORE_PATH=""
REMOTE_DOWNLOAD_PATH=""
REMOTE_BUILD_OUTPATH_FILE=""
LOCAL_ISO_PATH=""
DOWNLOAD_METHOD=""
STAGE_STARTED_AT=0

usage() {
  cat <<'EOF'
Usage:
  scripts/iso/build-remote.sh --host <ssh-host> --remote-dir <path> [options]

Required (flag or env):
  --host <ssh-host>         Remote Linux SSH host (or SSH config alias)
  --remote-dir <path>       Remote workspace root directory

Options:
  --iso <alias>             Flake ISO package alias (default: shaka-manual-installer-iso)
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

stage_start() {
  local name="$1"
  CURRENT_STAGE="${name}"
  STAGE_STARTED_AT="$(date +%s)"
  log "Stage start: ${name}"
}

stage_end() {
  local name="$1"
  if [[ "${STAGE_LOG_TIMESTAMPS}" == "1" && -n "${STAGE_STARTED_AT}" ]]; then
    local now elapsed
    now="$(date +%s)"
    elapsed=$(( now - STAGE_STARTED_AT ))
    log "Stage done: ${name} (${elapsed}s)"
  else
    log "Stage done: ${name}"
  fi
}

run_with_timeout() {
  local timeout_s="$1"
  shift
  local cmd_pid watchdog_pid status=0

  "$@" &
  cmd_pid=$!

  (
    sleep "${timeout_s}"
    if kill -0 "${cmd_pid}" >/dev/null 2>&1; then
      warn "build stage timeout after ${timeout_s}s; terminating process ${cmd_pid}"
      kill "${cmd_pid}" >/dev/null 2>&1 || true
      sleep 2
      kill -9 "${cmd_pid}" >/dev/null 2>&1 || true
    fi
  ) &
  watchdog_pid=$!

  wait "${cmd_pid}" || status=$?
  kill "${watchdog_pid}" >/dev/null 2>&1 || true
  wait "${watchdog_pid}" 2>/dev/null || true

  return "${status}"
}

download_iso_with_fallback() {
  local rsync_exit_code=0

  RSYNC_DOWNLOAD_CMD=(
    rsync -avP
    --timeout "${RSYNC_IO_TIMEOUT}"
    -e "${RSYNC_RSH}"
    "${REMOTE_HOST}:${REMOTE_DOWNLOAD_PATH}"
    "${LOCAL_ISO_PATH}"
  )
  if rsync --help 2>&1 | rg -q -- '--contimeout'; then
    RSYNC_DOWNLOAD_CMD=(rsync -avP --timeout "${RSYNC_IO_TIMEOUT}" --contimeout "${RSYNC_CONNECT_TIMEOUT}" -e "${RSYNC_RSH}" "${REMOTE_HOST}:${REMOTE_DOWNLOAD_PATH}" "${LOCAL_ISO_PATH}")
  fi

  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '[dry-run] mkdir -p %q\n' "${LOCAL_OUT_DIR}"
    print_cmd_array "[dry-run]" "${RSYNC_DOWNLOAD_CMD[@]}"
    printf '[dry-run] fallback: scp -o BatchMode=yes %q %q (if rsync fails)\n' \
      "${REMOTE_HOST}:${REMOTE_DOWNLOAD_PATH}" "${LOCAL_ISO_PATH}"
    DOWNLOAD_METHOD="rsync"
    return 0
  fi

  mkdir -p "${LOCAL_OUT_DIR}"

  if [[ "${NIX_ISO_TEST_FORCE_RSYNC_FAIL:-0}" == "1" ]]; then
    rsync_exit_code=12
    warn "rsync download failed (exit=${rsync_exit_code}), falling back to scp"
    rm -f "${LOCAL_ISO_PATH}" || true
    if "${SCP_BASE[@]}" "${REMOTE_HOST}:${REMOTE_DOWNLOAD_PATH}" "${LOCAL_ISO_PATH}"; then
      DOWNLOAD_METHOD="scp"
      return 0
    fi
    die "Download failed via forced rsync failure test and scp fallback"
  fi

  if "${RSYNC_DOWNLOAD_CMD[@]}"; then
    DOWNLOAD_METHOD="rsync"
  else
    rsync_exit_code=$?
    warn "rsync download failed (exit=${rsync_exit_code}), falling back to scp"

    # Clean up any partial file before retrying with scp.
    rm -f "${LOCAL_ISO_PATH}" || true

    if "${SCP_BASE[@]}" "${REMOTE_HOST}:${REMOTE_DOWNLOAD_PATH}" "${LOCAL_ISO_PATH}"; then
      DOWNLOAD_METHOD="scp"
    else
      die "Download failed via rsync (exit=${rsync_exit_code}) and scp fallback"
    fi
  fi
  [[ -f "${LOCAL_ISO_PATH}" ]] || die "Downloaded path is not a regular file: ${LOCAL_ISO_PATH}"
  return 0
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
  if [[ -n "${REMOTE_BUILD_OUTPATH_FILE}" ]]; then
    printf '[iso-remote][error] Remote build outpath file: %s\n' "${REMOTE_BUILD_OUTPATH_FILE}" >&2
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
REMOTE_BUILD_OUTPATH_FILE="${REMOTE_RUN_DIR}/.codex-build-outpath.txt"
LOCAL_ISO_PATH="${LOCAL_OUT_DIR%/}/${ISO_ALIAS}-${RUN_ID}.iso"

CURRENT_STAGE="validate-iso-alias"
LOCAL_FLAKE_REF="${REPO_ROOT}/${FLAKE_SUBPATH}"
if ! nix eval --raw "${LOCAL_FLAKE_REF}#packages.x86_64-linux.${ISO_ALIAS}.outPath" >/dev/null 2>&1; then
  AVAILABLE_ALIASES="$(
    nix eval --json "${LOCAL_FLAKE_REF}#packages.x86_64-linux" --apply 'x: builtins.attrNames x' 2>/dev/null || true
  )"
  die "Invalid ISO alias '${ISO_ALIAS}' for flake '${LOCAL_FLAKE_REF}'. Available aliases: ${AVAILABLE_ALIASES:-<unknown>}"
fi

read -r -a SSH_OPTS_ARR <<< "${NIX_ISO_SSH_OPTS}"
SSH_COMMON_OPTS=(
  -o BatchMode=yes
  -o ConnectTimeout="${SSH_CONNECT_TIMEOUT}"
  -o ServerAliveInterval=15
  -o ServerAliveCountMax=4
  -o RequestTTY=no
)
SSH_BASE=(ssh -n -T "${SSH_COMMON_OPTS[@]}" "${SSH_OPTS_ARR[@]}")
REMOTE_BASH_LC=(bash --noprofile --norc -lc)
RSYNC_RSH="ssh"
if [[ -n "${NIX_ISO_SSH_OPTS}" ]]; then
  RSYNC_RSH="ssh ${NIX_ISO_SSH_OPTS}"
fi
SCP_BASE=(scp "${SSH_COMMON_OPTS[@]}" "${SSH_OPTS_ARR[@]}")

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

stage_start "preflight-remote"
REMOTE_PREFLIGHT_CMD="command -v bash >/dev/null && command -v rsync >/dev/null && command -v nix >/dev/null"
if [[ "${DRY_RUN}" == "1" ]]; then
  printf '[dry-run] ssh %s bash --noprofile --norc -lc %q\n' "${REMOTE_HOST}" "${REMOTE_PREFLIGHT_CMD}"
else
  ssh_run "${REMOTE_BASH_LC[@]}" "${REMOTE_PREFLIGHT_CMD}" >/dev/null
fi
stage_end "preflight-remote"

RSYNC_EXCLUDES=(
  ".git/"
  ".direnv/"
  "result"
  "result-*"
  "archive/iso-out/"
  "scripts/docs/__pycache__/"
  ".DS_Store"
)

stage_start "upload"
RSYNC_UPLOAD_CMD=(
  rsync -a
  --timeout "${RSYNC_IO_TIMEOUT}"
  -e "${RSYNC_RSH}"
)
if rsync --help 2>&1 | rg -q -- '--contimeout'; then
  RSYNC_UPLOAD_CMD=(rsync -a --timeout "${RSYNC_IO_TIMEOUT}" --contimeout "${RSYNC_CONNECT_TIMEOUT}" -e "${RSYNC_RSH}")
fi
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
stage_end "upload"

stage_start "build"
REMOTE_NIX_BUILD_CMD="nix build --print-out-paths \".#packages.x86_64-linux.${ISO_ALIAS}\""
# `nixos-installer` is a subflake that needs access to the uploaded repo root for `rootSrc`.
# In pure eval, `path:..` inside the subflake can otherwise resolve to `/nix/store` after source copy.
if [[ "${FLAKE_SUBPATH}" != "." ]]; then
  REMOTE_NIX_BUILD_CMD="nix build --override-input rootSrc $(quote_sh "path:${REMOTE_RUN_DIR}") --print-out-paths \".#packages.x86_64-linux.${ISO_ALIAS}\""
fi
REMOTE_BUILD_CMD=$(
  cat <<EOF
set -euo pipefail
cd $(quote_sh "${REMOTE_BUILD_DIR}")
${REMOTE_NIX_BUILD_CMD} > $(quote_sh "${REMOTE_BUILD_OUTPATH_FILE}")
EOF
)

if [[ "${DRY_RUN}" == "1" ]]; then
  printf '[dry-run] ssh %s bash --noprofile --norc -lc %q\n' "${REMOTE_HOST}" "${REMOTE_BUILD_CMD}"
  REMOTE_STORE_PATH="/nix/store/<remote-built-iso>.iso"
else
  run_with_timeout "${REMOTE_BUILD_TIMEOUT}" ssh_run "${REMOTE_BASH_LC[@]}" "${REMOTE_BUILD_CMD}"
fi
stage_end "build"

stage_start "read-outpath"
if [[ "${DRY_RUN}" != "1" ]]; then
  REMOTE_BUILD_STDOUT="$(ssh_run "${REMOTE_BASH_LC[@]}" "cat $(quote_sh "${REMOTE_BUILD_OUTPATH_FILE}")")"
  REMOTE_BUILD_STDOUT="${REMOTE_BUILD_STDOUT//$'\r'/}"
  REMOTE_STORE_PATH="$(
    printf '%s\n' "${REMOTE_BUILD_STDOUT}" | awk '/^\/nix\/store\/.*\.iso$/ { found=$0 } END { if (found) print found }'
  )"
fi
stage_end "read-outpath"

[[ -n "${REMOTE_STORE_PATH}" ]] || die "Remote build did not return an output path"
case "${REMOTE_STORE_PATH}" in
  /nix/store/*) ;;
  *)
    die "Remote build output is not a Nix store path: ${REMOTE_STORE_PATH}"
    ;;
esac
case "${REMOTE_STORE_PATH}" in
  *.iso) ;;
  *)
    die "Remote build output does not look like an ISO path: ${REMOTE_STORE_PATH}"
    ;;
esac

stage_start "resolve-remote-download-path"
if [[ "${DRY_RUN}" == "1" ]]; then
  REMOTE_DOWNLOAD_PATH="/nix/store/<remote-built-iso>.iso"
else
  REMOTE_DOWNLOAD_STDOUT="$(
    ssh_run "${REMOTE_BASH_LC[@]}" "find $(quote_sh "${REMOTE_STORE_PATH}") -maxdepth 3 -type f -name '*.iso' | head -n1"
  )"
  REMOTE_DOWNLOAD_STDOUT="${REMOTE_DOWNLOAD_STDOUT//$'\r'/}"
  REMOTE_DOWNLOAD_PATH="$(
    printf '%s\n' "${REMOTE_DOWNLOAD_STDOUT}" | awk '/^\/nix\/store\/.*\.iso$/ { found=$0 } END { if (found) print found }'
  )"
fi
stage_end "resolve-remote-download-path"

[[ -n "${REMOTE_DOWNLOAD_PATH}" ]] || die "Could not resolve a downloadable ISO file under remote output path: ${REMOTE_STORE_PATH}"
case "${REMOTE_DOWNLOAD_PATH}" in
  /nix/store/*/*.iso | /nix/store/*.iso) ;;
  *)
    die "Resolved download path is not a valid Nix store ISO file path: ${REMOTE_DOWNLOAD_PATH}"
    ;;
esac

stage_start "download"
download_iso_with_fallback
stage_end "download"

stage_start "post-download"
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
stage_end "post-download"

stage_start "cleanup"
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
stage_end "cleanup"

CURRENT_STAGE="done"
log "Remote store path: ${REMOTE_STORE_PATH}"
log "Remote ISO file path: ${REMOTE_DOWNLOAD_PATH}"
log "Local ISO path: ${LOCAL_ISO_PATH}"
log "Download method: ${DOWNLOAD_METHOD}"
log "Local ISO size(bytes): ${LOCAL_SIZE}"
log "Local ISO sha256: ${LOCAL_SHA256}"
log "Done."
