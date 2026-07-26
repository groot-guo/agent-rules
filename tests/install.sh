#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT
fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}
assert_file_contains() {
  local file="$1"
  local expected="$2"
  grep -Fxq "$expected" "$file" || fail "expected '$expected' in $file"
}
assert_missing() {
  [[ ! -e "$1" ]] || fail "expected $1 to be absent"
}
CLAUDE_DIR="$WORK_DIR/claude"
mkdir -p "$CLAUDE_DIR/rules"
printf '@SOUL.md\ncustom instruction\n' > "$CLAUDE_DIR/CLAUDE.md"
printf 'original agent instructions\n' > "$CLAUDE_DIR/AGENTS.md"
printf 'legacy react rule\n' > "$CLAUDE_DIR/rules/react.md"
printf 'user rule\n' > "$CLAUDE_DIR/rules/custom.md"
mkdir -p "$CLAUDE_DIR/rules/go"
printf 'user Go rule\n' > "$CLAUDE_DIR/rules/go/custom.md"
CLAUDE_DIR="$CLAUDE_DIR" bash "$ROOT/install.sh"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "@AGENTS.md"
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "custom instruction"
assert_file_contains "$CLAUDE_DIR/AGENTS.md" "# Universal Hard Rules"
assert_missing "$CLAUDE_DIR/rules/react.md"
assert_file_contains "$CLAUDE_DIR/rules/custom.md" "user rule"
assert_file_contains "$CLAUDE_DIR/rules/go/custom.md" "user Go rule"
assert_file_contains "$CLAUDE_DIR/.agent-rules-managed-rules" "go/coding-style.md"
printf 'obsolete managed rule\n' > "$CLAUDE_DIR/rules/go/obsolete.md"
printf 'go/obsolete.md\n' >> "$CLAUDE_DIR/.agent-rules-managed-rules"
CLAUDE_DIR="$CLAUDE_DIR" bash "$ROOT/install.sh"
assert_missing "$CLAUDE_DIR/rules/go/obsolete.md"
CLAUDE_DIR="$CLAUDE_DIR" bash "$ROOT/install.sh" --uninstall
assert_file_contains "$CLAUDE_DIR/CLAUDE.md" "@SOUL.md"
assert_file_contains "$CLAUDE_DIR/AGENTS.md" "original agent instructions"
assert_file_contains "$CLAUDE_DIR/rules/react.md" "legacy react rule"
assert_missing "$CLAUDE_DIR/.agent-rules-managed-rules"
EMPTY_CLAUDE_DIR="$WORK_DIR/empty-claude"
mkdir -p "$EMPTY_CLAUDE_DIR"
CLAUDE_DIR="$EMPTY_CLAUDE_DIR" bash "$ROOT/install.sh"
CLAUDE_DIR="$EMPTY_CLAUDE_DIR" bash "$ROOT/install.sh" --uninstall
assert_missing "$EMPTY_CLAUDE_DIR/rules"
assert_missing "$EMPTY_CLAUDE_DIR/CLAUDE.md"
assert_missing "$EMPTY_CLAUDE_DIR/AGENTS.md"
printf 'PASS: install lifecycle\n'
