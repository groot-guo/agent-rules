#!/usr/bin/env bash
# agent-rules installer — idempotent, non-destructive, with uninstall
# Usage:
#   bash install.sh              # install
#   bash install.sh --dry-run    # preview (no writes)
#   bash install.sh --uninstall  # restore backups

set -euo pipefail

DRY_RUN=0
UNINSTALL=0
case "${1:-}" in
  --dry-run) DRY_RUN=1 ;;
  --uninstall) UNINSTALL=1 ;;
esac

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
RULES_DIR="$CLAUDE_DIR/rules"
BACKUP_DIR="$CLAUDE_DIR/.agent-rules-backup"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
stamp() { date +%Y%m%d-%H%M%S; }

# ---------- uninstall ----------
if [ "$UNINSTALL" = 1 ]; then
  echo "==> Uninstall: restore from $BACKUP_DIR"
  if [ ! -d "$BACKUP_DIR" ]; then
    echo "    no backup — nothing to restore"; exit 0
  fi
  if [ -d "$BACKUP_DIR/rules" ]; then
    if [ -d "$RULES_DIR" ]; then
      mv "$RULES_DIR" "$BACKUP_DIR/rules-replaced-$(stamp)"
    fi
    mv "$BACKUP_DIR/rules" "$RULES_DIR"
    echo "    restored rules/"
  fi
  if [ -f "$BACKUP_DIR/CLAUDE.md" ]; then
    if [ -f "$CLAUDE_MD" ]; then
      mv "$CLAUDE_MD" "$BACKUP_DIR/CLAUDE.md-replaced-$(stamp)"
    fi
    mv "$BACKUP_DIR/CLAUDE.md" "$CLAUDE_MD"
    echo "    restored CLAUDE.md"
  fi
  rm -f "$CLAUDE_DIR/AGENTS.md"
  echo "    removed AGENTS.md"
  echo "==> Done. Restart Claude Code."
  exit 0
fi

# ---------- install ----------
echo "==> Install agent-rules → $CLAUDE_DIR${DRY_RUN:+ (dry-run)}"

if [ ! -d "$CLAUDE_DIR" ]; then
  echo "ERROR: $CLAUDE_DIR not found — install Claude Code first" >&2
  exit 1
fi

wired=0
if [ -f "$CLAUDE_MD" ] && grep -q "^@AGENTS\.md$" "$CLAUDE_MD" 2>/dev/null; then
  wired=1
fi

if [ "$DRY_RUN" = 1 ]; then
  echo "  would back up rules/ + CLAUDE.md → $BACKUP_DIR (if not already)"
  echo "  would sync common/ + rules/*.md → $RULES_DIR/"
  echo "  would sync AGENTS.md → $CLAUDE_DIR/AGENTS.md"
  if [ "$wired" = 1 ]; then
    echo "  CLAUDE.md already wired to @AGENTS.md (skip)"
  else
    echo "  would rewire CLAUDE.md: drop @SOUL/@RULES/@RTK, add @AGENTS.md, keep rest"
  fi
  echo "==> Dry-run done. Run without --dry-run to apply."
  exit 0
fi

# 1. Back up (once)
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p "$BACKUP_DIR"
  if [ -d "$RULES_DIR" ]; then
    cp -r "$RULES_DIR" "$BACKUP_DIR/rules"
    echo "    backed up rules/"
  fi
  if [ -f "$CLAUDE_MD" ]; then
    cp "$CLAUDE_MD" "$BACKUP_DIR/CLAUDE.md"
    echo "    backed up CLAUDE.md"
  fi
else
  echo "    backup exists — skip"
fi

# 2. Sync common/ + rules/
mkdir -p "$RULES_DIR/common"
cp -r "$REPO/common/." "$RULES_DIR/common/"
cp "$REPO/rules/"*.md "$RULES_DIR/"
echo "    synced common/ + rules/"

# 3. AGENTS.md
cp "$REPO/AGENTS.md" "$CLAUDE_DIR/AGENTS.md"
echo "    synced AGENTS.md"

# 4. CLAUDE.md — drop @SOUL/@RULES/@RTK, add @AGENTS.md, keep the rest
if [ "$wired" = 1 ]; then
  echo "    CLAUDE.md already wired (skip)"
elif [ -f "$CLAUDE_MD" ]; then
  awk '/^@(SOUL|RULES|RTK)\.md$/ {next} {print}' "$CLAUDE_MD" > "$CLAUDE_MD.tmp"
  { echo "@AGENTS.md"; cat "$CLAUDE_MD.tmp"; } > "$CLAUDE_MD"
  rm -f "$CLAUDE_MD.tmp"
  echo "    rewired CLAUDE.md → @AGENTS.md (dropped @SOUL/@RULES/@RTK, kept rest)"
else
  echo "@AGENTS.md" > "$CLAUDE_MD"
  echo "    created CLAUDE.md → @AGENTS.md"
fi

echo "==> Done. Restart Claude Code to load."
echo "    Uninstall: bash install.sh --uninstall"
