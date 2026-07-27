#!/usr/bin/env bash
# agent-rules installer — detects coding agents and dispatches to adapters.
# Usage:
#   bash install.sh                  # auto-detect installed agents
#   bash install.sh --dry-run        # preview (no writes)
#   bash install.sh --uninstall      # restore backups
#   bash install.sh --agent <name>   # force one agent (claude, codex, ...)
set -euo pipefail
IFS=$'\n\t'

REPO="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=0
UNINSTALL=0
AGENT=""
export REPO DRY_RUN UNINSTALL

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --agent)
      [[ $# -ge 2 ]] || { printf 'ERROR: --agent needs a value\n' >&2; exit 2; }
      AGENT="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,7p' "$0"
      exit 0
      ;;
    *)
      printf "ERROR: unknown flag '%s' — use --dry-run, --uninstall, --agent <name>\n" "$1" >&2
      exit 2
      ;;
  esac
done

detect_agents() {
  # bash 3.2 (macOS default) errors on "${empty[@]}" under set -u, so guard on length.
  local found=()
  [[ -d "$HOME/.claude" ]] && found+=(claude)
  [[ -d "$HOME/.codex" ]] && found+=(codex)
  [[ -d "$HOME/.cursor" ]] && found+=(cursor)
  [[ ${#found[@]} -gt 0 ]] && printf '%s\n' "${found[@]}"
  return 0
}

if [[ -n "$AGENT" ]]; then
  agents=("$AGENT")
else
  agents=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && agents+=("$line")
  done < <(detect_agents)
  if [[ ${#agents[@]} -eq 0 ]]; then
    printf 'ERROR: no coding agent detected (~/.claude, ~/.codex, ~/.cursor). Install one first or use --agent <name>.\n' >&2
    exit 1
  fi
fi

( IFS=' '; printf '==> agent-rules: target agents: %s\n' "${agents[*]}" )

rc=0
for agent in "${agents[@]}"; do
  adapter="$REPO/adapters/$agent.sh"
  if [[ -f "$adapter" ]]; then
    if ! bash "$adapter"; then
      printf '  [fail] %s adapter exited non-zero\n' "$agent" >&2
      rc=1
    fi
  else
    printf '  [skip] %s: adapter not implemented yet (adapters/%s.sh missing)\n' "$agent" "$agent" >&2
    rc=1
  fi
done

printf '==> agent-rules: done. Restart your agent to load.\n'
exit "$rc"
