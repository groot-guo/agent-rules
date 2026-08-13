# Development Workflow

> Use for substantial or unfamiliar feature work. Tailor it to the change; it is not an automatic gate.

## 0. Research & Reuse (when useful)

Check for existing solutions when the area is unfamiliar, a dependency is being added, or reuse can materially reduce risk:
- **Code search**: `gh search code` / `gh search repos`
- **Docs**: Context7 or official docs for API behavior, version details
- **Registries**: npm / PyPI / crates.io / pkg.go.dev — prefer battle-tested libs over hand-rolled
- **Adaptable impls**: find OSS solving 80%+ → fork / port / wrap

Prefer a proven approach when it fits the project's constraints; do not add external research for a small, well-understood change.

## 1. Plan First

- For multi-step or risky work: write a brief breakdown and identify material dependencies or risks.
- Small, local changes can proceed directly.

## 2. Tests

- Add or update focused tests for core logic, regression fixes, and changes with meaningful behavioral risk.
- TDD is useful for complex algorithms and bug fixes, but is not required for every change.
- Follow the repository's existing coverage target; do not introduce a universal percentage target.

## 3. Review (optional)

- Before a code commit, recommend one environment-native route from AGENTS.md §1.
- Run it only when the user requests or accepts it; do not stack reviewers.
- If run, fix CRITICAL/HIGH findings and re-run the same route.

## 4. Commit

- Conventional commits
- AGENTS.md §1 (no proactive commit — wait for explicit user instruction)

## 5. Pre-Commit Checks

- Run the checks that are relevant and available for the changed scope.
- Check for merge conflicts when preparing a commit.
