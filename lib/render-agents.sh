#!/usr/bin/env bash
# Shared AGENTS.md renderer for agent adapters and tests.
# Resolves {{RULES_DIR}}/{{GUIDES_DIR}} placeholders and keeps only the
# current agent's <!-- agent-route:... --> block.
# Usage: render_agents_md <agent> <rules_dir> <guides_dir> <input-file>
set -euo pipefail
IFS=$'\n\t'

render_agents_md() {
  local agent="${1:?agent required}"
  local rules_dir="${2:?rules_dir required}"
  local guides_dir="${3:?guides_dir required}"
  local input="${4:?input required}"
  local open_markers close_markers

  case "$agent" in
    claude|codex) ;;
    *)
      printf 'ERROR: no AGENTS.md route block for agent: %s\n' "$agent" >&2
      return 1
      ;;
  esac

  open_markers="$(grep -Fxc "<!-- agent-route:$agent -->" "$input" || true)"
  close_markers="$(grep -Fxc "<!-- /agent-route:$agent -->" "$input" || true)"
  if [[ "$open_markers" -ne 1 || "$close_markers" -ne 1 ]]; then
    printf 'ERROR: AGENTS.md must contain exactly one route block for agent %s (open=%s close=%s)\n' "$agent" "$open_markers" "$close_markers" >&2
    return 1
  fi

  awk -v agent="$agent" -v rules_dir="$rules_dir" -v guides_dir="$guides_dir" '
    BEGIN { in_block = 0; keep = 0 }
    index($0, "<!-- agent-source-only -->") == 1 { in_note = 1; next }
    index($0, "<!-- /agent-source-only -->") == 1 { in_note = 0; next }
    in_note { next }
    index($0, "<!-- agent-route:") == 1 {
      in_block = 1
      keep = (index($0, "agent-route:" agent " -->") > 0)
      next
    }
    index($0, "<!-- /agent-route:") == 1 {
      in_block = 0
      keep = 0
      next
    }
    in_block && !keep { next }
    {
      line = $0
      gsub(/\{\{RULES_DIR\}\}/, rules_dir, line)
      gsub(/\{\{GUIDES_DIR\}\}/, guides_dir, line)
      print line
    }
  ' "$input"
}
