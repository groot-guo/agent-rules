# Universal Hard Rules

> Loaded every session. All projects. Priority top to bottom.
<!-- agent-source-only -->
> `{{RULES_DIR}}` / `{{GUIDES_DIR}}` are resolved per agent at install time; when reading this source directly, treat them as `rules/` and `guides/`.
<!-- /agent-source-only -->

## 1. Commit & Review

- Never commit proactively. Only commit on explicit "提交/commit/推一下"; "完成了/OK" is not an instruction.
- Before a code commit, recommend one environment-native review route. Review is opt-in: do not start it automatically, and do not block a commit when the user declines or does not request it.
- If a review is run, fix CRITICAL/HIGH findings and re-run the same route before committing. MEDIUM/LOW findings are reported but do not block unless the user requests a stricter gate.

**Suggested review route — choose one, do not stack reviewers**:
<!-- agent-route:claude -->
- **Claude Code** → suggest the native `/code-review` action; use it only when the user requests or accepts review. Use medium effort by default (<200 lines), high for refactors. No `--fix` by default.
<!-- /agent-route:claude -->
<!-- agent-route:codex -->
- **Codex Desktop** → suggest the native Review action for the uncommitted workspace; use it only when the user requests or accepts review.
- **Codex CLI** → suggest `codex review --uncommitted`; use `--base <branch>` for a branch diff.
<!-- /agent-route:codex -->

If review is unavailable, say so; do not claim it passed. A review covers staged, unstaged, and untracked changes, is read-only, and reports only reproducible issues introduced by the current changes. Codex `Auto-review` for sandbox approval is not code review.

## 2. Tool Selection

- Choose the smallest configured tool that can answer the question; optional tools are governed by their own installed instruction blocks
- Use `rg` and direct reads for exact text, known files, docs/config, and narrow single-file work
- For unfamiliar cross-file flows or change-impact analysis, use an available semantic/index tool when configured; otherwise fall back to `rg` and direct reads
- If an optional tool errors or returns insufficient results, fall back without blind retries or changing its installation/index state
- Prefer configured fast, narrow tools (for example `rg`); use RTK where it is available
- "How does X work" → inspect the smallest relevant source or configured relationship tool. No sub-agents or grep+read piles

## 3. Security Red Line

**Dangerous ops need explicit user consent**:
- `git push -f` / `reset --hard` / `branch -D` / `clean -f`
- `rm -rf` any dir
- Move/rename/delete user-owned files or directories when the target or impact is unclear
- Modify uncertain system behavior without verification
- SQL `DROP`/`TRUNCATE`/`DELETE/UPDATE` without WHERE
- Change CI/CD / deploy scripts
- Operate outside the user-provided scope
- Install/uninstall system software
- Unsure? Treat as dangerous

**No secrets in repo**: API keys, tokens, passwords, private keys, `.env` values, internal paths/IPs. Found committed → alert immediately.

**Third-party uploads** (diagrams, pastebin, gist) need consent.

## 4. Communication

- **Chinese** by default; technical terms in English
- Concise; no empty "以上完成了 XXX" summaries
- Code refs as `file_path:line`
- State material assumptions and blockers concisely
- No speculation — check logs/run commands first
- Mark unverifiable as "未验证"
- Ask before acting only when a choice materially changes scope, cost, safety, or an irreversible outcome. Otherwise make the smallest safe assumption and state it when useful.
- Suggest a simpler alternative when it materially reduces risk or effort; proceed with the user's explicit approach otherwise.

## 5. Engineering Discipline

- No refactoring unrelated to the task; no opportunistic cleanup; no "future" abstractions (YAGNI)
- No comments by default; if writing, why not what; no task-pointing comments
- Don't delete/modify user's existing tests; test fails → judge if real bug first; don't fix tests to pass
- New dependency → check existing deps for equivalents first; inform if added
- Do not make unrelated changes. Mention adjacent work separately rather than including it.
- For multi-step or high-risk work, state a short plan before acting.

## 6. Failure Handling

- Command failed → read the error before retrying. Retry only when new information or a transient cause justifies it.
- No root cause → tell user what's known + puzzling; no blind workaround
- Hook/skill error → report; don't swallow

## 7. Language Rules Index

Read only the relevant file for the work being done; do not load an entire language directory by default:

| Trigger | Rule file |
|---|---|
| Editing Go | `{{RULES_DIR}}/go/coding-style.md` |
| Editing Python | `{{RULES_DIR}}/python/coding-style.md` |
| Editing Rust | `{{RULES_DIR}}/rust/coding-style.md` |
| Writing SQL | `{{RULES_DIR}}/sql/coding-style.md` |
| Editing Shell | `{{RULES_DIR}}/shell/coding-style.md` |
| Editing TypeScript / JavaScript | `{{RULES_DIR}}/typescript/coding-style.md` |
| Editing React | `{{RULES_DIR}}/react/coding-style.md` (and TypeScript above, when applicable) |
| Editing HTML / CSS / frontend | `{{RULES_DIR}}/web/coding-style.md` |
| Writing tests or addressing an architecture, concurrency, or security concern | Read that language's matching `testing.md`, `patterns.md`, or `security.md` only if present |
| `gopls/` paths / `go-review` CL | `{{RULES_DIR}}/gopls-upstream.md` |
| GitHub ops / `gh` / `go-review` | `{{GUIDES_DIR}}/github.md` |

## 8. General Engineering Standards

Read on demand for the stated scenario; these are guidance, not automatic gates:

| Scenario | Rule file |
|---|---|
| New feature dev flow | `{{GUIDES_DIR}}/dev-workflow.md` |
| Writing tests | `{{GUIDES_DIR}}/testing.md` |
| Coding style | `{{GUIDES_DIR}}/coding-style.md` |
| Perf-related changes | `{{GUIDES_DIR}}/performance.md` |
| Security review / sensitive code | `{{GUIDES_DIR}}/security.md` |
| Design / architecture decisions | `{{GUIDES_DIR}}/patterns.md` |
