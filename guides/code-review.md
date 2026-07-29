# Code Review Standards

> Pre-commit self-check. AGENTS.md §1 selects the environment-native review route; this checklist supplements that route and is not a second review pass.

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
| HIGH | Bug / significant quality | BLOCK — must fix |
| MEDIUM | Maintainability | REPORT — does not block |
| LOW | Style | NOTE — optional |

Codex priority mapping: P0/P1 → CRITICAL/HIGH; P2/P3 → MEDIUM/LOW.

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

- No CRITICAL/HIGH → review passes
- Any CRITICAL/HIGH → fix and re-run the same environment-native route
- MEDIUM/LOW → report without blocking commit unless the user requested a stricter gate
