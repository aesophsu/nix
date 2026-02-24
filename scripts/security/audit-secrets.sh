#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

ALLOWLIST_FILE="${SECRETS_AUDIT_ALLOWLIST:-.secrets-audit-allowlist}"
TMP_MATCHES="$(mktemp)"
trap 'rm -f "${TMP_MATCHES}"' EXIT

# Heuristics for obvious credentials/tokens in tracked files.
PATTERN='(gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|token=[A-Za-z0-9._%:-]{12,}|Authorization:[[:space:]]*Bearer[[:space:]]+[A-Za-z0-9._-]{12,}|(password|passwd|psk)[[:space:]]*[:=][[:space:]]*"[^"]{8,}")'

git grep -nI -E "${PATTERN}" -- . >"${TMP_MATCHES}" || true

is_ignored_path() {
  local path="$1"
  case "${path}" in
    *.age|flake.lock|*.example.*|docs/generated/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_placeholder_match() {
  local line="$1"
  case "${line}" in
    *REPLACE_ME*|*YOUR_TOKEN*|*"<PASSWORD>"*|*"<TOKEN>"*|*"<ssh-host>"*)
      return 0
      ;;
    # Installer live ISO keeps this Wi-Fi PSK in cleartext by design.
    *zxcvbnm8*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

matches_allowlist() {
  local line="$1"
  [[ -f "${ALLOWLIST_FILE}" ]] || return 1
  while IFS= read -r regex; do
    [[ -z "${regex}" || "${regex}" =~ ^# ]] && continue
    if printf '%s\n' "${line}" | grep -Eq -- "${regex}"; then
      return 0
    fi
  done <"${ALLOWLIST_FILE}"
  return 1
}

FOUND=0
while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  path="${line%%:*}"

  if is_ignored_path "${path}"; then
    continue
  fi
  if is_placeholder_match "${line}"; then
    continue
  fi
  if matches_allowlist "${line}"; then
    continue
  fi

  if [[ "${FOUND}" == "0" ]]; then
    echo "[secret-audit] potential secret-like matches found in tracked files:" >&2
  fi
  FOUND=1
  echo "  ${line}" >&2
done <"${TMP_MATCHES}"

if [[ "${FOUND}" == "1" ]]; then
  echo "[secret-audit] FAIL" >&2
  exit 1
fi

echo "[secret-audit] OK: no tracked secret-like matches found"
