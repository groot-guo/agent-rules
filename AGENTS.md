# Universal Hard Rules

> Loaded every session. All projects. Priority top to bottom.

## 1. Commit Gate

Commit rules:
1. Never commit proactively. Only on explicit "提交/commit/推一下"; "完成了/OK" is not an instruction — report and wait
2. Before committing code changes, including refactors and tests, run exactly one environment-native review route
3. Fix CRITICAL/HIGH findings, then **re-run the same route** until no blocking findings remain

**Pre-commit self-check**: selected review passed or an exception is documented, blocking findings resolved, user agreed, message drafted, no secrets, no out-of-scope changes. Stop if any unmet.

**Review route — choose one, do not stack reviewers**:
- **Claude Code** → `/code-review`; effort=medium by default (<200 lines), high for refactors. No `--fix` by default
- **Codex** → run `codex review --uncommitted` automatically; use `--base <branch>` when the requested scope is a branch diff. If the CLI route is unavailable, use the surface's `/review`; review only, do not edit during the review pass
- **Other / unavailable route** → manually audit the diff using `~/.claude/guides/code-review.md` and report that fallback

Codex `Auto-review` for sandbox approval requests is not code review and does not satisfy this gate.

**Severity mapping**: Codex P0/P1 correspond to blocking CRITICAL/HIGH findings; P2/P3 correspond to non-blocking MEDIUM/LOW findings. For other reviewers, classify by equivalent impact.

**Non-blocking findings**: MEDIUM/LOW are reported but do not prevent commit unless the user asks for a stricter gate.

**Exceptions (skip review only, NOT skip "no proactive commit")**: pure docs/config literals; user says "skip review" (note risk); review tool errors after the manual fallback (inform).

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
| Pre-commit review / audit | `~/.claude/guides/code-review.md` |
| New feature dev flow | `~/.claude/guides/dev-workflow.md` |
| Writing tests | `~/.claude/guides/testing.md` |
| Coding style | `~/.claude/guides/coding-style.md` |
| Perf-related changes | `~/.claude/guides/performance.md` |
| Security review / sensitive code | `~/.claude/guides/security.md` |
| Design / architecture decisions | `~/.claude/guides/patterns.md` |
