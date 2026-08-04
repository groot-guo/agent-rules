#!/usr/bin/env bash
# Codex adapter for agent-rules. Env: REPO, DRY_RUN, UNINSTALL, optional CODEX_DIR.
set -euo pipefail
IFS=$'\n\t'
: "${REPO:?REPO must be set by install.sh}"
: "${DRY_RUN:=0}"
: "${UNINSTALL:=0}"
source "$REPO/lib/render-agents.sh"
CODEX_DIR="${CODEX_DIR:-$HOME/.codex}"
PAYLOAD_DIR="$CODEX_DIR/agent-rules"
RULES_DIR="$PAYLOAD_DIR/rules"
GUIDES_DIR="$PAYLOAD_DIR/guides"
AGENTS_MD="$CODEX_DIR/AGENTS.md"
OVERRIDE_MD="$CODEX_DIR/AGENTS.override.md"
MANAGED="$CODEX_DIR/.agent-rules-managed"
START_MARKER='<!-- AGENT_RULES_START -->'
END_MARKER='<!-- AGENT_RULES_END -->'
AGENTS_TMP=""
BLOCK_TMP=""
MANAGED_TMP=""
cleanup_tmp() {
  local tmp
  for tmp in "$AGENTS_TMP" "$BLOCK_TMP" "$MANAGED_TMP"; do
    [[ -z "$tmp" ]] || rm -f "$tmp"
  done
}
trap cleanup_tmp EXIT
validate_agents_markers() {
  local start_count end_count start_match end_match start_line end_line
  [[ -f "$AGENTS_MD" ]] || return 0
  start_count="$(grep -Fxc "$START_MARKER" "$AGENTS_MD" || true)"
  end_count="$(grep -Fxc "$END_MARKER" "$AGENTS_MD" || true)"
  if [[ "$start_count" -eq 0 && "$end_count" -eq 0 ]]; then
    return 0
  fi
  if [[ "$start_count" -ne 1 || "$end_count" -ne 1 ]]; then
    printf 'ERROR (codex): %s has incomplete or duplicate managed markers\n' "$AGENTS_MD" >&2
    return 1
  fi
  start_match="$(grep -nFx "$START_MARKER" "$AGENTS_MD")"
  end_match="$(grep -nFx "$END_MARKER" "$AGENTS_MD")"
  start_line="${start_match%%:*}"
  end_line="${end_match%%:*}"
  if [[ "$start_line" -ge "$end_line" ]]; then
    printf 'ERROR (codex): %s has managed markers in the wrong order\n' "$AGENTS_MD" >&2
    return 1
  fi
}
validate_managed_path() {
  local relative="$1"
  if [[ "$relative" = /* || "$relative" = *..* ]]; then
    printf 'ERROR (codex): unsafe managed path: %s\n' "$relative" >&2
    return 1
  fi
  case "$relative" in
    rules/*|guides/*) return 0 ;;
    *)
      printf 'ERROR (codex): unexpected managed path: %s\n' "$relative" >&2
      return 1
      ;;
  esac
}
validate_manifest() {
  local relative
  [[ -f "$MANAGED" ]] || return 0
  while IFS= read -r relative; do
    [[ -z "$relative" ]] || validate_managed_path "$relative"
  done < "$MANAGED"
}
validate_override_shadow() {
  if [[ -f "$OVERRIDE_MD" && -s "$OVERRIDE_MD" ]]; then
    printf 'ERROR (codex): %s is non-empty and shadows %s — Codex would ignore the managed AGENTS.md. Remove or rename the override, or merge it into AGENTS.md, then re-run.\n' "$OVERRIDE_MD" "$AGENTS_MD" >&2
    return 1
  fi
}
write_managed() {
  MANAGED_TMP="$(mktemp "$CODEX_DIR/.agent-rules-managed.XXXXXX")"
  ( cd "$REPO" && find guides rules -type f -print ) | sort -u > "$MANAGED_TMP"
  mv "$MANAGED_TMP" "$MANAGED"
  MANAGED_TMP=""
}
cleanup_stale() {
  local relative source target
  [[ -f "$MANAGED" ]] || return 0
  while IFS= read -r relative; do
    [[ -n "$relative" ]] || continue
    validate_managed_path "$relative"
    source="$REPO/$relative"
    target="$PAYLOAD_DIR/$relative"
    if [[ ! -e "$source" && -f "$target" ]]; then
      rm -f "$target"
      printf '    removed stale %s\n' "$relative"
    fi
  done < "$MANAGED"
}
render_block() {
  BLOCK_TMP="$(mktemp "$CODEX_DIR/.agent-rules-block.XXXXXX")"
  {
    printf '%s\n' "$START_MARKER"
    printf '<!-- Managed by agent-rules/adapters/codex.sh. -->\n'
    render_agents_md codex '~/.codex/agent-rules/rules' '~/.codex/agent-rules/guides' "$REPO/AGENTS.md"
    printf '\n%s\n' "$END_MARKER"
  } > "$BLOCK_TMP"
}
merge_agents() {
  render_block
  if [[ ! -f "$AGENTS_MD" ]]; then
    mv "$BLOCK_TMP" "$AGENTS_MD"
    BLOCK_TMP=""
    return 0
  fi
  AGENTS_TMP="$(mktemp "$CODEX_DIR/.agent-rules-agents.XXXXXX")"
  if ! grep -Fqx "$START_MARKER" "$AGENTS_MD"; then
    { cat "$BLOCK_TMP"; cat "$AGENTS_MD"; } > "$AGENTS_TMP"
  else
    awk -v start="$START_MARKER" -v end="$END_MARKER" -v block="$BLOCK_TMP" '
      $0 == start {
        while ((getline line < block) > 0) print line
        close(block)
        skip = 1
        next
      }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "$AGENTS_MD" > "$AGENTS_TMP"
  fi
  mv "$AGENTS_TMP" "$AGENTS_MD"
  AGENTS_TMP=""
  rm -f "$BLOCK_TMP"
  BLOCK_TMP=""
}
remove_agents_block() {
  [[ -f "$AGENTS_MD" ]] || return 0
  grep -Fqx "$START_MARKER" "$AGENTS_MD" || return 0
  AGENTS_TMP="$(mktemp "$CODEX_DIR/.agent-rules-agents.XXXXXX")"
  awk -v start="$START_MARKER" -v end="$END_MARKER" '
    $0 == start { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$AGENTS_MD" > "$AGENTS_TMP"
  if [[ -s "$AGENTS_TMP" ]]; then
    mv "$AGENTS_TMP" "$AGENTS_MD"
    AGENTS_TMP=""
  else
    rm -f "$AGENTS_MD" "$AGENTS_TMP"
    AGENTS_TMP=""
  fi
}
remove_managed_files() {
  local relative target
  if [[ -f "$MANAGED" ]]; then
    while IFS= read -r relative; do
      [[ -n "$relative" ]] || continue
      validate_managed_path "$relative"
      target="$PAYLOAD_DIR/$relative"
      [[ ! -f "$target" ]] || rm -f "$target"
    done < "$MANAGED"
    rm -f "$MANAGED"
  fi
  if [[ -d "$PAYLOAD_DIR" ]]; then
    find "$PAYLOAD_DIR" -depth -type d -exec rmdir {} \; 2>/dev/null || true
  fi
}
if [[ ! -d "$CODEX_DIR" ]]; then
  printf 'ERROR (codex): %s not found — install Codex first\n' "$CODEX_DIR" >&2
  exit 1
fi
validate_agents_markers
validate_manifest
if [[ "$UNINSTALL" -eq 1 ]]; then
  printf '==> Codex: uninstall from %s\n' "$CODEX_DIR"
  remove_agents_block
  remove_managed_files
  printf '==> Codex: done.\n'
  exit 0
fi
validate_override_shadow
if [[ -d "$PAYLOAD_DIR" && ! -f "$MANAGED" ]]; then
  printf 'ERROR (codex): %s exists without %s; refusing to take ownership\n' "$PAYLOAD_DIR" "$MANAGED" >&2
  exit 1
fi
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '==> Codex: dry-run → %s\n' "$CODEX_DIR"
  printf '  would sync rules/ + guides/ → %s/\n' "$PAYLOAD_DIR"
  printf '  would update managed manifest → %s\n' "$MANAGED"
  printf '  would merge managed rules into %s\n' "$AGENTS_MD"
  printf '==> Codex: dry-run done.\n'
  exit 0
fi

printf '==> Codex: install → %s\n' "$CODEX_DIR"
mkdir -p "$RULES_DIR" "$GUIDES_DIR"
cp -R "$REPO/rules/." "$RULES_DIR/"
cp -R "$REPO/guides/." "$GUIDES_DIR/"
cleanup_stale
if [[ -d "$PAYLOAD_DIR" ]]; then
  find "$PAYLOAD_DIR" -depth -type d -exec rmdir {} \; 2>/dev/null || true
fi
write_managed
printf '    synced rules/ + guides/\n'
merge_agents
printf '    merged AGENTS.md managed block\n'
printf '==> Codex: done.\n'
