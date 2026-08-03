#!/usr/bin/env bash
# Installer regression tests. Uses an isolated CLAUDE_DIR + --agent claude
# so detect never touches the real ~/.claude.
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_file_contains() {
  local file="$1" expected="$2"
  grep -Fxq "$expected" "$file" || fail "expected '$expected' in $file"
}
assert_exists() { [[ -e "$1" ]] || fail "expected $1 to exist"; }
assert_missing() { [[ ! -e "$1" ]] || fail "expected $1 to be absent"; }

CLAUDE_DIR="$WORK_DIR/claude"
mkdir -p "$CLAUDE_DIR/rules"
printf '@SOUL.md\n@RULES.md\n@RTK.md\ncustom instruction\n' > "$CLAUDE_DIR/CLAUDE.md"
printf 'original agent instructions\n' > "$CLAUDE_DIR/AGENTS.md"
# Legacy flat rule (pre per-language layout).
printf 'legacy react rule\n' > "$CLAUDE_DIR/rules/react.md"
# Legacy rules/common/ (pre guides split).
mkdir -p "$CLAUDE_DIR/rules/common"
printf 'legacy common rule\n' > "$CLAUDE_DIR/rules/common/legacy.md"
# Legacy rules/github.md (pre guides split).
printf 'legacy github rule\n' > "$CLAUDE_DIR/rules/github.md"
# User-owned rules (must be preserved).
printf 'user rule\n' > "$CLAUDE_DIR/rules/custom.md"
mkdir -p "$CLAUDE_DIR/rules/go"
printf 'user Go rule\n' > "$CLAUDE_DIR/rules/go/custom.md"

CLAUDE_DIR="$CLAUDE_DIR" bash "$ROOT/install.sh" --agent claude

# CLAUDE.md: @AGENTS.md prepended; all existing lines (@SOUL/@RULES/@RTK + custom) kept.
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "@AGENTS.md"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "@SOUL.md"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "@RULES.md"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "@RTK.md"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "custom instruction"
# AGENTS.md synced.
assert_file_contains "$CLAUDE_DIR/AGENTS.md" "# Universal Hard Rules"
# Legacy flat + rules/common/ + rules/github.md removed.
assert_missing "$CLAUDE_DIR/rules/react.md"
assert_missing "$CLAUDE_DIR/rules/common"
assert_missing "$CLAUDE_DIR/rules/github.md"
# github.md now lives in guides/.
assert_exists "$CLAUDE_DIR/guides/github.md"
# User files preserved.
assert_file_contains "$CLAUDE_DIR/rules/custom.md" "user rule"
assert_file_contains "$CLAUDE_DIR/rules/go/custom.md" "user Go rule"
# Managed manifest tracks both guides/ and rules/.
assert_file_contains "$CLAUDE_DIR/.agent-rules-managed" "go/coding-style.md"

# Stale cleanup: inject an obsolete managed entry, reinstall, must be removed.
printf 'obsolete managed rule\n' > "$CLAUDE_DIR/rules/go/obsolete.md"
printf 'go/obsolete.md\n' >> "$CLAUDE_DIR/.agent-rules-managed"
CLAUDE_DIR="$CLAUDE_DIR" bash "$ROOT/install.sh" --agent claude
assert_missing "$CLAUDE_DIR/rules/go/obsolete.md"

# Uninstall restores originals (CLAUDE.md back to @SOUL/@RULES/@RTK + custom).
CLAUDE_DIR="$CLAUDE_DIR" bash "$ROOT/install.sh" --agent claude --uninstall
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "@SOUL.md"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "@RULES.md"
assert_file_contains "$CLAUDE_DIR/AGENTS.md" "original agent instructions"
assert_file_contains "$CLAUDE_DIR/rules/react.md" "legacy react rule"
assert_missing "$CLAUDE_DIR/.agent-rules-managed"
# guides/ was absent originally → removed on uninstall.
assert_missing "$CLAUDE_DIR/guides"

# Empty dir: install + uninstall must not crash.
EMPTY_CLAUDE_DIR="$WORK_DIR/empty-claude"
mkdir -p "$EMPTY_CLAUDE_DIR"
CLAUDE_DIR="$EMPTY_CLAUDE_DIR" bash "$ROOT/install.sh" --agent claude
CLAUDE_DIR="$EMPTY_CLAUDE_DIR" bash "$ROOT/install.sh" --agent claude --uninstall
assert_missing "$EMPTY_CLAUDE_DIR/rules"
assert_missing "$EMPTY_CLAUDE_DIR/guides"
assert_missing "$EMPTY_CLAUDE_DIR/CLAUDE.md"
assert_missing "$EMPTY_CLAUDE_DIR/AGENTS.md"

# .absent marker cleanup: uninstall must remove markers to avoid data loss on next cycle.
ABSENT_TEST_DIR="$WORK_DIR/absent-test"
mkdir -p "$ABSENT_TEST_DIR"
CLAUDE_DIR="$ABSENT_TEST_DIR" bash "$ROOT/install.sh" --agent claude >/dev/null
CLAUDE_DIR="$ABSENT_TEST_DIR" bash "$ROOT/install.sh" --agent claude --uninstall >/dev/null
assert_missing "$ABSENT_TEST_DIR/.agent-rules-backup/rules.absent"
assert_missing "$ABSENT_TEST_DIR/.agent-rules-backup/guides.absent"
assert_missing "$ABSENT_TEST_DIR/.agent-rules-backup/CLAUDE.md.absent"
assert_missing "$ABSENT_TEST_DIR/.agent-rules-backup/AGENTS.md.absent"
# User writes their own content after uninstall.
mkdir -p "$ABSENT_TEST_DIR/rules/go"
printf 'user rule\n' > "$ABSENT_TEST_DIR/rules/go/mine.md"
printf 'user CLAUDE.md\n' > "$ABSENT_TEST_DIR/CLAUDE.md"
# 2nd install + uninstall: user content must survive (not moved to *-replaced-*).
CLAUDE_DIR="$ABSENT_TEST_DIR" bash "$ROOT/install.sh" --agent claude >/dev/null
CLAUDE_DIR="$ABSENT_TEST_DIR" bash "$ROOT/install.sh" --agent claude --uninstall >/dev/null
grep -q "user rule" "$ABSENT_TEST_DIR/rules/go/mine.md" || fail "user rule lost after 2nd cycle"
grep -q "user CLAUDE.md" "$ABSENT_TEST_DIR/CLAUDE.md" || fail "user CLAUDE.md lost after 2nd cycle"

printf 'PASS: install lifecycle\n'
