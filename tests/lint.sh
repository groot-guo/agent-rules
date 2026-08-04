#!/usr/bin/env bash
# Validate rule file structure, AGENTS.md placeholders, and per-agent rendered references.
# Run: bash tests/lint.sh
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LITERAL_TILDE=$'\x7e'
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
    if grep -q '^paths:' "$f"; then
      fail "guides/ file must not have 'paths:' (not auto-loaded): $f"
    fi
  done < <(find guides -name '*.md' -type f)
fi

# 3. AGENTS.md source: placeholders only, no raw agent paths, one route block per agent.
! grep -E "${LITERAL_TILDE}/\.(claude|codex)/" AGENTS.md >/dev/null || fail 'AGENTS.md must not hardcode agent paths (use {{RULES_DIR}}/{{GUIDES_DIR}})'
for placeholder in '{{RULES_DIR}}' '{{GUIDES_DIR}}'; do
  grep -Fq "$placeholder" AGENTS.md || fail "AGENTS.md missing placeholder: $placeholder"
done
leftover="$(grep -oE '\{\{[A-Z_]+\}\}' AGENTS.md | sort -u | grep -Fvx '{{RULES_DIR}}' | grep -Fvx '{{GUIDES_DIR}}' || true)"
[[ -z "$leftover" ]] || fail "unknown placeholders in AGENTS.md: $leftover"
for agent in claude codex; do
  [[ "$(grep -Fxc "<!-- agent-route:$agent -->" AGENTS.md || true)" -eq 1 ]] || fail "AGENTS.md must have exactly one open route block for $agent"
  [[ "$(grep -Fxc "<!-- /agent-route:$agent -->" AGENTS.md || true)" -eq 1 ]] || fail "AGENTS.md must have exactly one close route block for $agent"
done
[[ "$(grep -Fxc '<!-- agent-source-only -->' AGENTS.md || true)" -eq 1 ]] || fail 'AGENTS.md must have exactly one source-only note block'
[[ "$(grep -Fxc '<!-- /agent-source-only -->' AGENTS.md || true)" -eq 1 ]] || fail 'AGENTS.md must close its source-only note block'

# 4. AGENTS.md placeholder route-table references must resolve to repo files.
while IFS= read -r ref; do
  rel="$(printf '%s' "$ref" | sed 's#^{{RULES_DIR}}#rules#; s#^{{GUIDES_DIR}}#guides#; s,/$,,' )"
  [[ -n "$rel" && -e "$ROOT/$rel" ]] || fail "AGENTS.md references missing path: $ref (-> $rel)"
done < <(grep -oE '\{\{(RULES|GUIDES)_DIR\}\}/[A-Za-z0-9/._-]+' AGENTS.md | sort -u)

# 5. Render both agent variants: placeholder-free, marker-free, only its own
#    review route, and all path references resolve to repo files.
source lib/render-agents.sh
CLAUDE_TMP="$(mktemp)"
CODEX_TMP="$(mktemp)"
MISSING_ROUTE_TMP="$(mktemp)"
trap 'rm -f "$CLAUDE_TMP" "$CODEX_TMP" "$MISSING_ROUTE_TMP"' EXIT
render_agents_md claude '~/.claude/rules' '~/.claude/guides' AGENTS.md > "$CLAUDE_TMP"
render_agents_md codex '~/.codex/agent-rules/rules' '~/.codex/agent-rules/guides' AGENTS.md > "$CODEX_TMP"

validate_render() {
  local file="$1" agent="$2" strip="$3"
  ! grep -Fq '{{' "$file" || fail "rendered $agent AGENTS.md still contains placeholders"
  ! grep -Fq '<!-- agent-route:' "$file" || fail "rendered $agent AGENTS.md still contains route markers"
  ! grep -Fq 'agent-source-only' "$file" || fail "rendered $agent AGENTS.md still contains source-only note"
  while IFS= read -r ref; do
    rel="$(printf '%s' "$ref" | sed "s,^${strip},,; s,/$,,")"
    [[ -n "$rel" && -e "$ROOT/$rel" ]] || fail "rendered $agent AGENTS.md references missing path: $ref (-> $rel)"
  done < <(grep -oE "${LITERAL_TILDE}/\.(claude|codex)/[A-Za-z0-9/._-]+" "$file" | sort -u)
}

validate_render "$CLAUDE_TMP" claude "${LITERAL_TILDE}/.claude/"
validate_render "$CODEX_TMP" codex "${LITERAL_TILDE}/.codex/agent-rules/"
grep -Fq '**Claude Code**' "$CLAUDE_TMP" || fail 'Claude render must include its review route'
! grep -Fq '**Codex**' "$CLAUDE_TMP" || fail 'Claude render must not include the Codex review route'
grep -Fq '**Codex CLI**' "$CODEX_TMP" || fail 'Codex render must include its review route'
! grep -Fq '**Claude Code**' "$CODEX_TMP" || fail 'Codex render must not include the Claude review route'

# 6. Renderer fails closed when an agent's route block is missing from the input.
printf '# t\n<!-- agent-route:codex -->\n- Codex\n<!-- /agent-route:codex -->\n' > "$MISSING_ROUTE_TMP"
if render_agents_md claude r g "$MISSING_ROUTE_TMP" >/dev/null 2>&1; then
  fail 'render must fail when the requested agent route block is missing'
fi

printf 'PASS: rules lint\n'
