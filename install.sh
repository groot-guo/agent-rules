#!/usr/bin/env bash
# agent-rules installer — idempotent, non-destructive, with uninstall
# Usage:
#   bash install.sh              # install
#   bash install.sh --dry-run    # preview (no writes)
#   bash install.sh --uninstall  # restore backups
set -euo pipefail
IFS=$'\n\t'
DRY_RUN=0
UNINSTALL=0
case "${1:-}" in
  --dry-run) DRY_RUN=1 ;;
  --uninstall) UNINSTALL=1 ;;
  "") ;;
  *)
    printf "ERROR: unknown flag '%s' — use --dry-run, --uninstall, or none\n" "$1" >&2
    exit 2
    ;;
esac
REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
RULES_DIR="$CLAUDE_DIR/rules"
BACKUP_DIR="$CLAUDE_DIR/.agent-rules-backup"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
AGENTS_MD="$CLAUDE_DIR/AGENTS.md"
MANAGED_RULES="$CLAUDE_DIR/.agent-rules-managed-rules"
TMP=""
stamp() {
  date +%Y%m%d-%H%M%S
}
cleanup_tmp() {
  [[ -z "$TMP" ]] || rm -f "$TMP"
}
trap cleanup_tmp EXIT
backup_file() {
  local source="$1"
  local backup="$2"
  local label="$3"
  if [[ -e "$backup" || -e "$backup.absent" ]]; then
    return
  fi
  if [[ -f "$source" ]]; then
    cp -p "$source" "$backup"
    printf '    backed up %s\n' "$label"
  else
    : > "$backup.absent"
  fi
}
cleanup_stale_rules() {
  local relative source target
  if [[ -f "$MANAGED_RULES" ]]; then
    while IFS= read -r relative; do
      [[ -n "$relative" ]] || continue
      if [[ "$relative" == common/* ]]; then
        source="$REPO/$relative"
      else
        source="$REPO/rules/$relative"
      fi
      target="$RULES_DIR/$relative"
      if [[ ! -e "$source" && -f "$target" ]]; then
        rm -f "$target"
        printf '    removed stale rule %s\n' "$relative"
      fi
    done < "$MANAGED_RULES"
  fi
  # Versions before the per-language layout left these managed flat files behind.
  local legacy_rule
  for legacy_rule in go.md python.md react.md rust.md shell.md sql.md typescript.md web.md; do
    target="$RULES_DIR/$legacy_rule"
    if [[ -f "$target" ]]; then
      rm -f "$target"
      printf '    removed legacy rule %s\n' "$legacy_rule"
    fi
  done
}
write_managed_rules() {
  TMP="$(mktemp "$CLAUDE_DIR/.agent-rules-managed-rules.XXXXXX")"
  {
    (
      cd "$REPO"
      find common -type f -print
    )
    (
      cd "$REPO/rules"
      find . -type f -print | sed 's#^\./##'
    )
  } | sort -u > "$TMP"
  mv "$TMP" "$MANAGED_RULES"
  TMP=""
}
restore_file() {
  local target="$1"
  local backup="$2"
  local label="$3"
  if [[ -f "$backup" ]]; then
    if [[ -f "$target" ]]; then
      mv "$target" "$BACKUP_DIR/${label}-replaced-$(stamp)"
    fi
    mv "$backup" "$target"
    printf '    restored %s\n' "$label"
  elif [[ -f "$backup.absent" && -f "$target" ]]; then
    mv "$target" "$BACKUP_DIR/${label}-replaced-$(stamp)"
    printf '    removed installed %s\n' "$label"
  fi
}
# ---------- uninstall ----------
if [[ "$UNINSTALL" -eq 1 ]]; then
  printf '==> Uninstall: restore from %s\n' "$BACKUP_DIR"
  if [[ ! -d "$BACKUP_DIR" ]]; then
    printf '    no backup — nothing to restore\n'
    exit 0
  fi
  if [[ -d "$BACKUP_DIR/rules" ]]; then
    if [[ -d "$RULES_DIR" ]]; then
      mv "$RULES_DIR" "$BACKUP_DIR/rules-replaced-$(stamp)"
    fi
    mv "$BACKUP_DIR/rules" "$RULES_DIR"
    printf '    restored rules/\n'
  elif [[ -f "$BACKUP_DIR/rules.absent" && -d "$RULES_DIR" ]]; then
    mv "$RULES_DIR" "$BACKUP_DIR/rules-replaced-$(stamp)"
    printf '    removed installed rules/\n'
  fi
  restore_file "$CLAUDE_MD" "$BACKUP_DIR/CLAUDE.md" "CLAUDE.md"
  restore_file "$AGENTS_MD" "$BACKUP_DIR/AGENTS.md" "AGENTS.md"
  rm -f "$MANAGED_RULES"
  printf '==> Done. Restart Claude Code.\n'
  exit 0
fi
# ---------- install ----------
if [[ ! -d "$CLAUDE_DIR" ]]; then
  printf 'ERROR: %s not found — install Claude Code first\n' "$CLAUDE_DIR" >&2
  exit 1
fi
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '==> Install agent-rules → %s (dry-run)\n' "$CLAUDE_DIR"
  printf '  would back up rules/, CLAUDE.md, and AGENTS.md → %s (if not already)\n' "$BACKUP_DIR"
  printf '  would sync managed common/ + rules/ files → %s/\n' "$RULES_DIR"
  printf '  would remove stale managed and legacy flat rules\n'
  printf '  would sync AGENTS.md → %s\n' "$AGENTS_MD"
  printf '==> Dry-run done. Run without --dry-run to apply.\n'
  exit 0
fi
printf '==> Install agent-rules → %s\n' "$CLAUDE_DIR"

# 1. Back up each original target once.
mkdir -p "$BACKUP_DIR"
if [[ ! -d "$BACKUP_DIR/rules" && ! -e "$BACKUP_DIR/rules.absent" ]]; then
  if [[ -d "$RULES_DIR" ]]; then
    cp -R "$RULES_DIR" "$BACKUP_DIR/rules"
    printf '    backed up rules/\n'
  else
    : > "$BACKUP_DIR/rules.absent"
  fi
fi
backup_file "$CLAUDE_MD" "$BACKUP_DIR/CLAUDE.md" "CLAUDE.md"
backup_file "$AGENTS_MD" "$BACKUP_DIR/AGENTS.md" "AGENTS.md"

# 2. Sync current files, then remove only stale files from the managed set.
mkdir -p "$RULES_DIR/common"
cp -R "$REPO/common/." "$RULES_DIR/common/"

for source_dir in "$REPO/rules/"*/; do
  [[ -d "$source_dir" ]] || continue
  dir_name="$(basename "$source_dir")"
  mkdir -p "$RULES_DIR/$dir_name"
  cp -R "$source_dir/." "$RULES_DIR/$dir_name/"
done

shopt -s nullglob
flat_rules=("$REPO"/rules/*.md)
if [[ ${#flat_rules[@]} -gt 0 ]]; then
  cp "${flat_rules[@]}" "$RULES_DIR/"
fi

cleanup_stale_rules
write_managed_rules
printf '    synced managed common/ + rules/\n'

# 3. AGENTS.md
cp "$REPO/AGENTS.md" "$AGENTS_MD"
printf '    synced AGENTS.md\n'

# 4. CLAUDE.md — drop @SOUL/@RULES/@RTK, add @AGENTS.md, keep the rest.
if [[ -f "$CLAUDE_MD" ]] && grep -qx '@AGENTS\.md' "$CLAUDE_MD"; then
  printf '    CLAUDE.md already wired (skip)\n'
elif [[ -f "$CLAUDE_MD" ]]; then
  TMP="$(mktemp)"
  awk '/^@(SOUL|RULES|RTK)\.md$/ {next} {print}' "$CLAUDE_MD" > "$TMP"
  { printf '@AGENTS.md\n'; awk '{print}' "$TMP"; } > "$CLAUDE_MD"
  rm -f "$TMP"
  TMP=""
  printf '    rewired CLAUDE.md → @AGENTS.md (dropped @SOUL/@RULES/@RTK, kept rest)\n'
else
  printf '@AGENTS.md\n' > "$CLAUDE_MD"
  printf '    created CLAUDE.md → @AGENTS.md\n'
fi

printf '==> Done. Restart Claude Code to load.\n'
printf '    Uninstall: bash install.sh --uninstall\n'
