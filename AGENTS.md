# Universal Hard Rules

> Loaded every session. All projects. Priority top to bottom.

## 1. Commit Gate

Three iron rules:
1. Code changes must pass `/code-review` before `git commit`
2. Findings → fix → **re-run** review until clean
3. Never commit proactively. Only on explicit "提交/commit/推一下"; "完成了/OK" is not an instruction — report and wait

**Pre-commit self-check**: review passed, findings resolved, re-run clean, user agreed, message drafted, no secrets, no out-of-scope changes. Stop if any unmet.

**`/code-review` usage**: effort=medium default (<200 lines), high for refactors. No `--fix` by default — report, let user decide.

**Exceptions (skip review only, NOT skip "no proactive commit")**: pure docs/config literals; user says "skip review" (note risk); review tool errors (manual self-check, inform).

## 2. Tool Priority

- `.codegraph/` present → **codegraph_*** first; no grep+read re-indexing (see MCP instructions)
- No `.codegraph/` → grep/find; tell user `codegraph init -i` is available
- Terminal via RTK (hook auto-rewrites); Read not cat; no `find . -name` for symbols
- "How does X work" → one codegraph_context + one explore; no sub-agents, no grep+read piles

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
| `*.go` / `go.mod` | `~/.claude/rules/go.md` |
| `*.py` / `pyproject.toml` | `~/.claude/rules/python.md` |
| `*.rs` / `Cargo.toml` | `~/.claude/rules/rust.md` |
| Writing SQL | `~/.claude/rules/sql.md` |
| `*.sh` / `*.bash` | `~/.claude/rules/shell.md` |
| `*.ts` / `*.tsx` / `*.js` / `*.jsx` | `~/.claude/rules/typescript.md` |
| `*.tsx` / `*.jsx` / React components / hooks | `~/.claude/rules/react.md` |
| `*.html` / `*.css` / `*.scss` / `*.less` / frontend | `~/.claude/rules/web.md` |
| `gopls/` paths / `go-review` CL | `~/.claude/rules/gopls-upstream.md` |
| GitHub ops / `gh` / `go-review` | `~/.claude/rules/github.md` |

## 8. General Engineering Standards

Proactively Read by scenario:

| Scenario | Rule file |
|---|---|
| Pre-commit review / audit | `~/.claude/rules/common/code-review.md` |
| New feature dev flow | `~/.claude/rules/common/dev-workflow.md` |
| Writing tests | `~/.claude/rules/common/testing.md` |
| Coding style | `~/.claude/rules/common/coding-style.md` |
| Perf-related changes | `~/.claude/rules/common/performance.md` |
