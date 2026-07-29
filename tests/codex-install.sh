#!/usr/bin/env bash
# Codex adapter lifecycle tests. Uses isolated CODEX_DIR directories.
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
LITERAL_TILDE=$'\x7e'
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_contains() {
  local file="$1" expected="$2"
  grep -Fq "$expected" "$file" || fail "expected '$expected' in $file"
}
assert_exists() { [[ -e "$1" ]] || fail "expected $1 to exist"; }
assert_missing() { [[ ! -e "$1" ]] || fail "expected $1 to be absent"; }
install_codex() {
  local codex_dir="$1"
  shift
  CODEX_DIR="$codex_dir" bash "$ROOT/install.sh" --agent codex "$@"
}

# Install preserves existing instructions and never touches Codex command rules.
CODEX_DIR="$WORK_DIR/codex"
mkdir -p "$CODEX_DIR/rules"
printf 'user global instruction\n' > "$CODEX_DIR/AGENTS.md"
printf 'prefix_rule(pattern=["git", "status"], decision="allow")\n' > "$CODEX_DIR/rules/default.rules"
install_codex "$CODEX_DIR"

assert_contains "$CODEX_DIR/AGENTS.md" '<!-- AGENT_RULES_START -->'
assert_contains "$CODEX_DIR/AGENTS.md" '<!-- AGENT_RULES_END -->'
assert_contains "$CODEX_DIR/AGENTS.md" 'user global instruction'
assert_contains "$CODEX_DIR/AGENTS.md" "${LITERAL_TILDE}/.codex/agent-rules/rules/go/"
! grep -Fq "${LITERAL_TILDE}/.claude/rules/" "$CODEX_DIR/AGENTS.md" || fail 'Claude rule path leaked into Codex AGENTS.md'
! grep -Fq "${LITERAL_TILDE}/.claude/guides/" "$CODEX_DIR/AGENTS.md" || fail 'Claude guide path leaked into Codex AGENTS.md'
assert_exists "$CODEX_DIR/agent-rules/rules/go/coding-style.md"
assert_exists "$CODEX_DIR/agent-rules/guides/code-review.md"
assert_contains "$CODEX_DIR/.agent-rules-managed" 'rules/go/coding-style.md'
assert_contains "$CODEX_DIR/rules/default.rules" 'prefix_rule'

# Reinstall replaces one managed block and removes stale managed files.
printf 'obsolete\n' > "$CODEX_DIR/agent-rules/rules/go/obsolete.md"
printf 'rules/go/obsolete.md\n' >> "$CODEX_DIR/.agent-rules-managed"
printf 'user payload\n' > "$CODEX_DIR/agent-rules/custom.md"
install_codex "$CODEX_DIR"
[[ "$(grep -Fxc '<!-- AGENT_RULES_START -->' "$CODEX_DIR/AGENTS.md")" -eq 1 ]] || fail 'duplicate START marker'
[[ "$(grep -Fxc '<!-- AGENT_RULES_END -->' "$CODEX_DIR/AGENTS.md")" -eq 1 ]] || fail 'duplicate END marker'
assert_missing "$CODEX_DIR/agent-rules/rules/go/obsolete.md"

# Uninstall removes only managed content.
install_codex "$CODEX_DIR" --uninstall
assert_contains "$CODEX_DIR/AGENTS.md" 'user global instruction'
! grep -Fq '<!-- AGENT_RULES_START -->' "$CODEX_DIR/AGENTS.md" || fail 'managed block remains after uninstall'
assert_contains "$CODEX_DIR/rules/default.rules" 'prefix_rule'
assert_contains "$CODEX_DIR/agent-rules/custom.md" 'user payload'
assert_missing "$CODEX_DIR/agent-rules/rules/go/coding-style.md"
assert_missing "$CODEX_DIR/.agent-rules-managed"

# Empty install/uninstall leaves no AGENTS.md or payload directory.
EMPTY_DIR="$WORK_DIR/empty"
mkdir -p "$EMPTY_DIR"
install_codex "$EMPTY_DIR"
install_codex "$EMPTY_DIR" --uninstall
assert_missing "$EMPTY_DIR/AGENTS.md"
assert_missing "$EMPTY_DIR/agent-rules"

# Dry-run performs preflight without writing.
DRY_DIR="$WORK_DIR/dry"
mkdir -p "$DRY_DIR"
install_codex "$DRY_DIR" --dry-run
assert_missing "$DRY_DIR/AGENTS.md"
assert_missing "$DRY_DIR/agent-rules"
assert_missing "$DRY_DIR/.agent-rules-managed"

# An unowned namespace is a hard conflict.
CONFLICT_DIR="$WORK_DIR/conflict"
mkdir -p "$CONFLICT_DIR/agent-rules"
printf 'keep me\n' > "$CONFLICT_DIR/agent-rules/custom.md"
if install_codex "$CONFLICT_DIR" >/dev/null 2>&1; then
  fail 'unowned namespace should fail'
fi
assert_contains "$CONFLICT_DIR/agent-rules/custom.md" 'keep me'
assert_missing "$CONFLICT_DIR/AGENTS.md"

# Malformed markers fail without modifying AGENTS.md or payload files.
MALFORMED_DIR="$WORK_DIR/malformed"
mkdir -p "$MALFORMED_DIR"
printf '<!-- AGENT_RULES_START -->\nuser content\n' > "$MALFORMED_DIR/AGENTS.md"
if install_codex "$MALFORMED_DIR" >/dev/null 2>&1; then
  fail 'malformed markers should fail'
fi
assert_contains "$MALFORMED_DIR/AGENTS.md" 'user content'
assert_missing "$MALFORMED_DIR/agent-rules"

# Unsafe manifest entries fail before uninstall changes user content.
UNSAFE_DIR="$WORK_DIR/unsafe"
mkdir -p "$UNSAFE_DIR/agent-rules"
printf 'user content\n' > "$UNSAFE_DIR/AGENTS.md"
printf 'rules/../../outside\n' > "$UNSAFE_DIR/.agent-rules-managed"
if install_codex "$UNSAFE_DIR" --uninstall >/dev/null 2>&1; then
  fail 'unsafe manifest should fail'
fi
assert_contains "$UNSAFE_DIR/AGENTS.md" 'user content'
assert_exists "$UNSAFE_DIR/.agent-rules-managed"

printf 'PASS: Codex install lifecycle\n'
