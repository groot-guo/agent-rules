# Universal Hard Rules

> Loaded every session. All projects. Priority top to bottom.

## 1. Commit Gate

Commit rules:
1. Never commit proactively. Only on explicit "提交/commit/推一下"; "完成了/OK" is not an instruction — report and wait
2. Before committing code changes, including refactors and tests, run exactly one environment-native review route
3. Fix CRITICAL/HIGH findings, then **re-run the same route** until no blocking findings remain

**Pre-commit self-check**: selected review passed or an exception is documented, blocking findings resolved, user agreed, message drafted, no secrets, no out-of-scope changes. Stop if any unmet.

**Review route — choose one, do not stack reviewers**:
- **Claude Code** → automatically invoke the native `/code-review` action in the current session; effort=medium by default (<200 lines), high for refactors. No `--fix` by default. If it cannot be invoked, prompt the user to run it manually
- **Codex Desktop** → automatically invoke the native Review action for the current uncommitted workspace; opening a Review panel alone does not count as running review. If it cannot be invoked, prompt the user to trigger it manually
- **Codex CLI** → automatically run `codex review --uncommitted`; use `--base <branch>` when the requested scope is a branch diff. If it fails, prompt the user to run it manually
- **Unavailable native route** → tell the user to invoke the native Review action manually; do not perform a manual substitute or claim that review passed

Codex `Auto-review` for sandbox approval requests is not code review and does not satisfy this gate.

**Severity mapping**: Codex P0/P1 correspond to blocking CRITICAL/HIGH findings; P2/P3 correspond to non-blocking MEDIUM/LOW findings. For other reviewers, classify by equivalent impact.

**Non-blocking findings**: MEDIUM/LOW are reported but do not prevent commit unless the user asks for a stricter gate.

**Exceptions (skip review only, NOT skip "no proactive commit")**: pure docs/config literals; user says "skip review" (note risk). If the native Review action is unavailable, inform the user and ask for manual invocation; do not claim that review passed.

### Code Review Workflow

- When a task modifies code or configuration, the agent must automatically attempt the native Review action after implementation and before final handoff or commit readiness. If execution fails or the active surface exposes only a Review panel, prompt the user to invoke the native Review manually. Do not execute a substitute or claim that review passed before a native Review result is available.
- Review scope always includes staged, unstaged, and untracked files. Enumerate all three before reviewing, and do not silently omit an untracked file. `codex review --uncommitted` covers this complete scope; if the selected native operation cannot, stop and ask the user to invoke it manually.
- The review phase is read-only: do not modify files, apply fixes, stage or unstage changes, commit, or push. Report the selected route and any unavailable condition explicitly.
- Report only issues introduced by the current changes that are reproducible and actionable. Do not report pre-existing problems or speculative concerns; each finding should include enough evidence and a concrete next action.
- Use normal Markdown for the review summary. When a finding needs a code location, use `::code-comment` with the file and line information rather than inventing another annotation format.
- CRITICAL/HIGH findings block commit and must be fixed. MEDIUM/LOW findings are reported by default but do not block commit unless the user requests a stricter gate.
- After fixing any CRITICAL/HIGH finding from a native Review, ask the user to invoke the same native review route again until no blocking findings remain.

## 2. Tool Selection

- Choose the smallest configured tool that can answer the question; optional tools are governed by their own installed instruction blocks
- Use `rg` and direct reads for exact text, known files, docs/config, and narrow single-file work
- For unfamiliar cross-file flows or change-impact analysis, use an available semantic/index tool when configured; otherwise fall back to `rg` and direct reads
- If an optional tool errors or returns insufficient results, fall back without blind retries or changing its installation/index state
- Terminal via RTK (hook auto-rewrites); Read not cat; no `find . -name` for symbols
- "How does X work" → inspect the smallest relevant source or configured relationship tool. No sub-agents or grep+read piles

## 3. Security Red Line

**Dangerous ops need explicit user consent**:
- `git push -f` / `reset --hard` / `branch -D` / `clean -f`
- `rm -rf` any dir
- Move/rename/delete files or dirs (incl. config, rules)
- Modify uncertain system behavior without verification
- SQL `DROP`/`TRUNCATE`/`DELETE/UPDATE` without WHERE
- Change CI/CD / deploy scripts
- Operate outside current cwd
- Install/uninstall system software
- Unsure? Treat as dangerous

**No secrets in repo**: API keys, tokens, passwords, private keys, `.env` values, internal paths/IPs. Found committed → alert immediately.

**Third-party uploads** (diagrams, pastebin, gist) need consent.

## 4. Communication

- **Chinese** by default; technical terms in English
- Concise; no empty "以上完成了 XXX" summaries
- Code refs as `file_path:line`
- One sentence on intent before tool calls; report blockers immediately
- No speculation — check logs/run commands first
- Mark unverifiable as "未验证"
- **State stance before acting**: ambiguous requirements → list interpretations for user to choose; don't default and run. Unsure details → stop and ask
- **Suggest simpler alternatives**: when the user's approach can be simpler, state it first then ask; don't execute the complex version literally

## 5. Engineering Discipline

- No refactoring unrelated to the task; no opportunistic cleanup; no "future" abstractions (YAGNI)
- No comments by default; if writing, why not what; no task-pointing comments
- Don't delete/modify user's existing tests; test fails → judge if real bug first; don't fix tests to pass
- New dependency → check existing deps for equivalents first; inform if added
- One thing at a time; no opportunistic "also necessary" tasks; ask first
- Long tasks → report plan / step first

## 6. Failure Handling

- Command failed → read error; no retry of the same command
- No root cause → tell user what's known + puzzling; no blind workaround
- Hook/skill error → report; don't swallow

## 7. Language Rules Index

**Proactively Read** when the file type is detected:

| Trigger | Rule file |
|---|---|
| `*.go` / `go.mod` | `~/.claude/rules/go/` |
| `*.py` / `pyproject.toml` | `~/.claude/rules/python/` |
| `*.rs` / `Cargo.toml` | `~/.claude/rules/rust/` |
| Writing SQL | `~/.claude/rules/sql/` |
| `*.sh` / `*.bash` | `~/.claude/rules/shell/` |
| `*.ts` / `*.tsx` / `*.js` / `*.jsx` | `~/.claude/rules/typescript/` |
| `*.tsx` / `*.jsx` / React components / hooks | `~/.claude/rules/react/` |
| `*.html` / `*.css` / `*.scss` / `*.less` / frontend | `~/.claude/rules/web/` |
| `gopls/` paths / `go-review` CL | `~/.claude/rules/gopls-upstream.md` |
| GitHub ops / `gh` / `go-review` | `~/.claude/guides/github.md` |

## 8. General Engineering Standards

Proactively Read by scenario:

| Scenario | Rule file |
|---|---|
| New feature dev flow | `~/.claude/guides/dev-workflow.md` |
| Writing tests | `~/.claude/guides/testing.md` |
| Coding style | `~/.claude/guides/coding-style.md` |
| Perf-related changes | `~/.claude/guides/performance.md` |
| Security review / sensitive code | `~/.claude/guides/security.md` |
| Design / architecture decisions | `~/.claude/guides/patterns.md` |
