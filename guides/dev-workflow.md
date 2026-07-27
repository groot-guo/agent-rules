# Development Workflow

> Auto-loaded for new feature work. Full flow from "before coding" to commit.

## 0. Research & Reuse (before any new code)

Find existing solutions first:
- **Code search**: `gh search code` / `gh search repos`
- **Docs**: Context7 or official docs for API behavior, version details
- **Registries**: npm / PyPI / crates.io / pkg.go.dev — prefer battle-tested libs over hand-rolled
- **Adaptable impls**: find OSS solving 80%+ → fork / port / wrap

Prefer porting a proven approach over writing net-new. Extends AGENTS.md §5 (deps check) to any new implementation.

## 1. Plan First

- Implementation plan before coding: breakdown, architecture, task list
- Identify deps + risks
- Long tasks → phases (AGENTS.md §5)

## 2. TDD

- RED → failing test
- GREEN → minimal impl
- IMPROVE → refactor
- Verify ≥ 80%

Not mandatory for everything, but required for core logic / complex algorithms / regression-prone code.

## 3. Review

- Run `common/code-review.md` checklist right after coding
- Fix CRITICAL/HIGH
- See AGENTS.md §1 Commit Gate

## 4. Commit

- Conventional commits
- AGENTS.md §1 (no proactive commit — wait for explicit user instruction)

## 5. Pre-Commit Checks

- CI / lint / test green
- No merge conflicts
- Branch up to date
