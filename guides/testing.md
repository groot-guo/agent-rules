# Testing Standards

> Auto-loaded when writing tests. Language specifics in `rules/<lang>.md`.

## Coverage

- Minimum 80%
- New features must have tests

## Types (all required)

1. **Unit** — functions / utils / isolated logic
2. **Integration** — API / DB / inter-module
3. **E2E** — critical user flows

## TDD

1. Write test (RED)
2. Run — fails
3. Minimal impl (GREEN)
4. Run — passes
5. Refactor (IMPROVE)
6. Verify coverage

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
