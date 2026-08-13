# Testing Standards

> Use when adding or changing tests. Language specifics are in `rules/<lang>/testing.md`.

## Coverage

- Add focused tests when behavior, core logic, or a regression risk changes.
- Follow an existing repository coverage target when one exists; do not impose a universal 80% target.

## Choose the right level

1. **Unit** — functions / utils / isolated logic
2. **Integration** — API / DB / inter-module
3. **E2E** — critical user flows

Use the smallest level that proves the intended behavior. Add integration or E2E coverage when the change crosses that boundary or affects a critical flow.

## TDD (optional)

1. Write test (RED)
2. Run — fails
3. Minimal impl (GREEN)
4. Run — passes
5. Refactor (IMPROVE)
6. Verify relevant coverage or behavior

## Structure — AAA

- **Arrange** — prepare data/state
- **Act** — execute
- **Assert** — verify

## Naming

Describe behavior, not implementation:
- ✅ `test_login_with_expired_token_raises_auth_error`
- ✅ `returns_empty_when_no_match`
- ❌ `test1` / `test_function`

## When Tests Fail

- Judge: test wrong or impl wrong? (AGENTS.md §5 — don't fix tests to pass)
- Check isolation (side effects from other tests)
- Check mocks
