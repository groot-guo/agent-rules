#!/usr/bin/env bash
# Edge case tests: bash 3.2 compatibility, unknown adapter exit code, CLAUDE.md rewrite behavior.
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

# Test 1: no agent detected under bash 3.2 + set -u (must not leak "unbound variable").
echo "=== Test 1: no agent detected ==="
HOME="$WORK_DIR" bash "$ROOT/install.sh" 2>&1 | tee "$WORK_DIR/no-agent.log"
[[ $? -eq 1 ]] || fail "no agent should exit 1"
grep -q "no coding agent detected" "$WORK_DIR/no-agent.log" || fail "missing error message"
! grep -q "unbound variable" "$WORK_DIR/no-agent.log" || fail "leaked bash internals"

# Test 2: unknown adapter exits 1.
echo "=== Test 2: unknown adapter ==="
bash "$ROOT/install.sh" --agent nonexistent 2>&1 | tee "$WORK_DIR/unknown.log"
[[ $? -eq 1 ]] || fail "unknown adapter should exit 1"
grep -q "adapter not implemented yet" "$WORK_DIR/unknown.log" || fail "missing skip message"

# Test 3: CLAUDE.md rewrite preserves existing @ references.
echo "=== Test 3: CLAUDE.md rewrite ==="
C="$WORK_DIR/claude"
mkdir -p "$C"
printf '@SOUL.md\n@RULES.md\n@RTK.md\ncustom line\n' > "$C/CLAUDE.md"
CLAUDE_DIR="$C" bash "$ROOT/install.sh" --agent claude >/dev/null
grep -q '@AGENTS.md' "$C/CLAUDE.md" || fail "@AGENTS.md missing"
grep -q '@SOUL.md' "$C/CLAUDE.md" || fail "@SOUL.md removed (should be preserved)"
grep -q '@RULES.md' "$C/CLAUDE.md" || fail "@RULES.md removed (should be preserved)"
grep -q '@RTK.md' "$C/CLAUDE.md" || fail "@RTK.md removed (should be preserved)"
grep -q 'custom line' "$C/CLAUDE.md" || fail "custom line removed (should be preserved)"

printf 'PASS: edge cases\n'
