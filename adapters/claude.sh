#!/usr/bin/env bash
# Claude Code adapter for agent-rules.
# Env: REPO, DRY_RUN, UNINSTALL. CLAUDE_DIR defaults to ~/.claude.
set -euo pipefail
IFS=$'\n\t'

: "${REPO:?REPO must be set by install.sh}"
: "${DRY_RUN:=0}"
: "${UNINSTALL:=0}"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

RULES_DIR="$CLAUDE_DIR/rules"
GUIDES_DIR="$CLAUDE_DIR/guides"
BACKUP_DIR="$CLAUDE_DIR/.agent-rules-backup"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
AGENTS_MD="$CLAUDE_DIR/AGENTS.md"
MANAGED="$CLAUDE_DIR/.agent-rules-managed"
LEGACY_MANAGED="$CLAUDE_DIR/.agent-rules-managed-rules"
TMP=""

stamp() { date +%Y%m%d-%H%M%S; }
cleanup_tmp() { [[ -z "$TMP" ]] || rm -f "$TMP"; }
trap cleanup_tmp EXIT

backup_file() {
  local source="$1" backup="$2" label="$3"
  [[ -e "$backup" || -e "$backup.absent" ]] && return
  if [[ -f "$source" ]]; then
    cp -p "$source" "$backup"
    printf '    backed up %s\n' "$label"
  else
    : > "$backup.absent"
  fi
}

restore_file() {
  local target="$1" backup="$2" label="$3"
  if [[ -f "$backup" ]]; then
    [[ -f "$target" ]] && mv "$target" "$BACKUP_DIR/${label}-replaced-$(stamp)"
    mv "$backup" "$target"
    printf '    restored %s\n' "$label"
  elif [[ -f "$backup.absent" && -f "$target" ]]; then
    mv "$target" "$BACKUP_DIR/${label}-replaced-$(stamp)"
    printf '    removed installed %s\n' "$label"
  fi
  rm -f "$backup.absent"
}

write_managed() {
  TMP="$(mktemp "$CLAUDE_DIR/.agent-rules-managed.XXXXXX")"
  {
    ( cd "$REPO" && find guides -type f -print 2>/dev/null || true )
    ( cd "$REPO/rules" && find . -type f -print | sed 's#^\./##' )
  } | sort -u > "$TMP"
  mv "$TMP" "$MANAGED"
  TMP=""
}

cleanup_stale() {
  local relative source target legacy_rule
  if [[ -f "$MANAGED" ]]; then
    while IFS= read -r relative; do
      [[ -n "$relative" ]] || continue
      if [[ "$relative" == guides/* ]]; then
        source="$REPO/$relative"
        target="$CLAUDE_DIR/$relative"
      else
        source="$REPO/rules/$relative"
        target="$RULES_DIR/$relative"
      fi
      if [[ ! -e "$source" && -f "$target" ]]; then
        rm -f "$target"
        printf '    removed stale %s\n' "$relative"
      fi
    done < "$MANAGED"
  fi
  # Pre per-language layout left these flat files behind.
  for legacy_rule in go.md python.md react.md rust.md shell.md sql.md typescript.md web.md; do
    target="$RULES_DIR/$legacy_rule"
    if [[ -f "$target" ]]; then
      rm -f "$target"
      printf '    removed legacy rule %s\n' "$legacy_rule"
    fi
  done
  # common/ moved to guides/: remove the old rules/common/ install.
  if [[ -d "$RULES_DIR/common" ]]; then
    case "$RULES_DIR/common" in
      "$CLAUDE_DIR"/*) rm -rf "$RULES_DIR/common"; printf '    removed legacy rules/common/ (now guides/)\n' ;;
    esac
  fi
  # github.md moved from rules/ to guides/.
  if [[ -f "$RULES_DIR/github.md" ]]; then
    rm -f "$RULES_DIR/github.md"
    printf '    removed legacy rules/github.md (now guides/)\n'
  fi
}

# ---------- uninstall ----------
if [[ "$UNINSTALL" -eq 1 ]]; then
  printf '==> Claude: uninstall from %s\n' "$CLAUDE_DIR"
  if [[ ! -d "$BACKUP_DIR" ]]; then
    printf '    no backup — nothing to restore\n'
    exit 0
  fi
  if [[ -d "$BACKUP_DIR/rules" ]]; then
    [[ -d "$RULES_DIR" ]] && mv "$RULES_DIR" "$BACKUP_DIR/rules-replaced-$(stamp)"
    mv "$BACKUP_DIR/rules" "$RULES_DIR"
    printf '    restored rules/\n'
  elif [[ -f "$BACKUP_DIR/rules.absent" && -d "$RULES_DIR" ]]; then
    mv "$RULES_DIR" "$BACKUP_DIR/rules-replaced-$(stamp)"
    printf '    removed installed rules/\n'
  fi
  rm -f "$BACKUP_DIR/rules.absent"
  if [[ -d "$BACKUP_DIR/guides" ]]; then
    [[ -d "$GUIDES_DIR" ]] && mv "$GUIDES_DIR" "$BACKUP_DIR/guides-replaced-$(stamp)"
    mv "$BACKUP_DIR/guides" "$GUIDES_DIR"
    printf '    restored guides/\n'
  elif [[ -f "$BACKUP_DIR/guides.absent" && -d "$GUIDES_DIR" ]]; then
    mv "$GUIDES_DIR" "$BACKUP_DIR/guides-replaced-$(stamp)"
    printf '    removed installed guides/\n'
  fi
  rm -f "$BACKUP_DIR/guides.absent"
  restore_file "$CLAUDE_MD" "$BACKUP_DIR/CLAUDE.md" "CLAUDE.md"
  restore_file "$AGENTS_MD" "$BACKUP_DIR/AGENTS.md" "AGENTS.md"
  rm -f "$MANAGED" "$LEGACY_MANAGED"
  printf '==> Claude: done.\n'
  exit 0
fi

# ---------- preflight ----------
if [[ ! -d "$CLAUDE_DIR" ]]; then
  printf 'ERROR (claude): %s not found — install Claude Code first\n' "$CLAUDE_DIR" >&2
  exit 1
fi

# ---------- dry-run ----------
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '==> Claude: dry-run → %s\n' "$CLAUDE_DIR"
  printf '  would back up rules/, guides/, CLAUDE.md, AGENTS.md → %s\n' "$BACKUP_DIR"
  printf '  would sync guides/ → %s/\n' "$GUIDES_DIR"
  printf '  would sync rules/ → %s/\n' "$RULES_DIR"
  printf '  would remove stale managed + legacy rules\n'
  printf '  would sync AGENTS.md → %s\n' "$AGENTS_MD"
  printf '  would rewire CLAUDE.md → @AGENTS.md\n'
  printf '==> Claude: dry-run done.\n'
  exit 0
fi

printf '==> Claude: install → %s\n' "$CLAUDE_DIR"

# Migrate legacy managed-manifest name from prior versions.
if [[ -f "$LEGACY_MANAGED" && ! -f "$MANAGED" ]]; then
  mv "$LEGACY_MANAGED" "$MANAGED"
  printf '    migrated legacy managed manifest\n'
fi

# 1. Back up originals once.
mkdir -p "$BACKUP_DIR"
if [[ ! -d "$BACKUP_DIR/rules" && ! -e "$BACKUP_DIR/rules.absent" ]]; then
  if [[ -d "$RULES_DIR" ]]; then
    cp -R "$RULES_DIR" "$BACKUP_DIR/rules"
    printf '    backed up rules/\n'
  else
    : > "$BACKUP_DIR/rules.absent"
  fi
fi
if [[ ! -d "$BACKUP_DIR/guides" && ! -e "$BACKUP_DIR/guides.absent" ]]; then
  if [[ -d "$GUIDES_DIR" ]]; then
    cp -R "$GUIDES_DIR" "$BACKUP_DIR/guides"
    printf '    backed up guides/\n'
  else
    : > "$BACKUP_DIR/guides.absent"
  fi
fi
backup_file "$CLAUDE_MD" "$BACKUP_DIR/CLAUDE.md" "CLAUDE.md"
backup_file "$AGENTS_MD" "$BACKUP_DIR/AGENTS.md" "AGENTS.md"

# 2. Sync guides/ and rules/, then remove only stale files from the managed set.
mkdir -p "$GUIDES_DIR"
cp -R "$REPO/guides/." "$GUIDES_DIR/"

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

cleanup_stale
write_managed
printf '    synced guides/ + rules/\n'

# 3. AGENTS.md
cp "$REPO/AGENTS.md" "$AGENTS_MD"
printf '    synced AGENTS.md\n'

# 4. CLAUDE.md — drop @SOUL/@RULES/@RTK, add @AGENTS.md, keep the rest.
if [[ -f "$CLAUDE_MD" ]] && grep -qx '@AGENTS\.md' "$CLAUDE_MD"; then
  printf '    CLAUDE.md already wired (skip)\n'
elif [[ -f "$CLAUDE_MD" ]]; then
  TMP="$(mktemp)"
  { printf '@AGENTS.md\n'; awk '{print}' "$CLAUDE_MD"; } > "$TMP"
  mv "$TMP" "$CLAUDE_MD"
  TMP=""
  printf '    added @AGENTS.md to CLAUDE.md (kept existing content)\n'
else
  printf '@AGENTS.md\n' > "$CLAUDE_MD"
  printf '    created CLAUDE.md → @AGENTS.md\n'
fi

printf '==> Claude: done.\n'
