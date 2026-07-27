# Code Review Standards

> Pre-commit self-check. Complements `/code-review` (which scans diffs for bugs + CLAUDE.md compliance) — this covers dimensions the tool skips: coverage, file size, debug residue, severity triage, security triggers.

## Checklist

Before commit:
- [ ] Functions < 50 lines, files < 800 lines
- [ ] No deep nesting (> 4 levels → early return)
- [ ] Errors explicit — no `_ = err` swallow
- [ ] No hardcoded secrets / tokens / internal paths
- [ ] No debug residue (`fmt.Println` / `console.log` / `print`)
- [ ] New features tested, coverage ≥ 80%
- [ ] Clear naming, no abbreviations (`config` not `cfg`)
- [ ] No out-of-scope changes, no opportunistic refactors

## Severity

| Level | Meaning | Action |
|---|---|---|
| CRITICAL | Security hole / data loss | BLOCK — must fix |
| HIGH | Bug / significant quality | WARN — should fix |
| MEDIUM | Maintainability | INFO — consider |
| LOW | Style | NOTE — optional |

## Security Triggers

Code touching these needs a security review (see AGENTS.md red line):
- Authn / authz
- User input
- DB queries (injection)
- Filesystem (path traversal)
- External API calls
- Crypto / payment

## Common Issues

- **Security**: hardcoded creds / SQL concat / XSS / path traversal / auth bypass
- **Quality**: large funcs / files / deep nesting / missing error handling / mutable shared state
- **Perf**: N+1 / missing pagination / unbounded queries / no cache

## Pass Criteria

- No CRITICAL/HIGH → commit
- Only HIGH → commit with caution, note risk
- Any CRITICAL → block
