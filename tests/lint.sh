#!/usr/bin/env bash
# Validate rule file structure and AGENTS.md route-table references.
# Run: bash tests/lint.sh
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

# 1. rules/ files are L1 (auto-loaded by file type) — must declare `paths:`.
while IFS= read -r f; do
  [[ "$(head -1 "$f")" == "---" ]] || fail "rules/ file missing frontmatter: $f"
  grep -q '^paths:' "$f" || fail "rules/ file missing 'paths:' frontmatter: $f"
done < <(find rules -name '*.md' -type f)

# 2. guides/ files are L2 (not auto-loaded; Read on demand via §7/§8) — must NOT declare `paths:`.
if [[ -d guides ]]; then
  while IFS= read -r f; do
    grep -q '^paths:' "$f" && fail "guides/ file must not have 'paths:' (not auto-loaded): $f" || true
  done < <(find guides -name '*.md' -type f)
fi

# 3. AGENTS.md §7/§8 route-table references must resolve to repo files.
while IFS= read -r ref; do
  rel="$(printf '%s' "$ref" | sed 's,^~/.claude/,,; s,/$,,')"
  [[ -n "$rel" && -e "$ROOT/$rel" ]] || fail "AGENTS.md references missing path: $ref (-> $rel)"
done < <(grep -oE '~/\.claude/(rules|guides)/[A-Za-z0-9/._-]+' AGENTS.md | sort -u)

printf 'PASS: rules lint\n'
