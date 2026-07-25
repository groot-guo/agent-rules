---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/requirements.txt"
---

# Python Testing

> Extends `common/testing.md`.

## Framework

- `pytest` over unittest
- Fixtures over setUp/tearDown
- Parameterize: `@pytest.mark.parametrize`
- Slow tests: `@pytest.mark.slow`; CI runs fast by default
- Names describe behavior: `test_login_with_expired_token_raises_auth_error`
- Mock with `pytest-mock`, not bare `unittest.mock`

## Patterns

```python
# Fixture with scope
@pytest.fixture(scope="module")
def db_session():
    engine = create_engine(TEST_DB_URL)
    with engine.begin() as conn:
        yield conn

# Parametrized
@pytest.mark.parametrize("input,expected", [
    ("hello", 5),
    ("", 0),
    ("你好", 2),
])
def test_strlen(input: str, expected: int):
    assert char_count(input) == expected

# Async test
@pytest.mark.anyio
async def test_fetch_user():
    user = await fetch_user(1)
    assert user.name == "Alice"
```

## Coverage Targets

| Layer | Target |
|---|---|
| Pure utility functions | ≥ 90% |
| Service / business logic | ≥ 80% |
| API endpoints | Key flows covered |
