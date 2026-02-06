#!/usr/bin/env bash
# Cleanup expired / low-value files under ~ (max depth 3 subdirs).
# Protected: .ssh, .secrets, .config, Library, Applications.
# Excluded from type cleanup: Code/nix/archive/
#
# Usage:
#   cleanup-home.sh [--dry-run] [--months N]
#   --dry-run   Only list candidates, do not delete.
#   --months N  For age-based cleanup, files not modified in N months (default: 6).

set -e

HOME_DIR="${HOME:-/Users/sue}"
DRY_RUN=false
MONTHS=6

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --months)  MONTHS="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

DAYS=$((MONTHS * 30))
ARCHIVE_DIR="$HOME_DIR/Code/nix/archive"
TYPE_LIST="$ARCHIVE_DIR/cleanup_type_candidates.txt"
AGE_LIST="$ARCHIVE_DIR/cleanup_age_candidates.txt"

# ---- By type: .DS_Store, *.tmp, *.temp, *.bak, *.backup, *.log, .obsolete (maxdepth 4 = 0..3 levels)
collect_type() {
  cd "$HOME_DIR" || exit 1
  ( find . -maxdepth 4 \
    \( -path './.ssh' -o -path './.secrets' -o -path './.config' -o -path './Library' -o -path './Applications' \) -prune -o \
    \( -name '.DS_Store' -o -name '*.tmp' -o -name '*.temp' -o -name '*.bak' -o -name '*.backup' -o -name '*.log' -o -name '.obsolete' \) -type f -print 2>/dev/null
  ) | grep -v 'Code/nix/archive' || true | sed 's|^\./||' | sort -u
}

# ---- By age: only in .cache (excl nix), .npm, .codex/tmp, .zsh_sessions
collect_age() {
  cd "$HOME_DIR" || exit 1
  { ( find .cache -mindepth 1 -mtime +"$DAYS" 2>/dev/null | grep -v '\.cache/nix' || true )
    find .npm -mindepth 1 -mtime +"$DAYS" 2>/dev/null || true
    find .codex/tmp -mindepth 1 -mtime +"$DAYS" 2>/dev/null || true
    find .zsh_sessions -mindepth 1 -mtime +"$DAYS" 2>/dev/null || true
  } | sed 's|^\./||' | sort -u
}

# ---- Main
mkdir -p "$ARCHIVE_DIR"

echo "=== Type-based candidates (excluding Code/nix/archive) ==="
collect_type > "$TYPE_LIST"
type_count=$(wc -l < "$TYPE_LIST" | tr -d ' ')
echo "Count: $type_count"
cat "$TYPE_LIST"

echo ""
echo "=== Age-based candidates (not modified in ${MONTHS} months) ==="
collect_age > "$AGE_LIST"
age_count=$(wc -l < "$AGE_LIST" | tr -d ' ')
echo "Count: $age_count"
cat "$AGE_LIST"

if [[ "$DRY_RUN" == true ]]; then
  echo ""
  echo "Dry-run: no files deleted. Lists saved to $ARCHIVE_DIR."
  exit 0
fi

echo ""
echo "=== Deleting type-based candidates ==="
while IFS= read -r p; do
  [[ -z "$p" ]] && continue
  f="$HOME_DIR/$p"
  if [[ -f "$f" ]]; then
    rm -f "$f" && echo "Removed: $p"
  fi
done < "$TYPE_LIST"

echo "=== Deleting age-based candidates ==="
while IFS= read -r p; do
  [[ -z "$p" ]] && continue
  f="$HOME_DIR/$p"
  if [[ -e "$f" ]]; then
    if [[ -d "$f" ]]; then
      rmdir "$f" 2>/dev/null && echo "Removed dir: $p" || true
    else
      rm -f "$f" && echo "Removed: $p"
    fi
  fi
done < "$AGE_LIST"

echo "Done. Lists kept in $ARCHIVE_DIR."
