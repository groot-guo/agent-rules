---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/requirements.txt"
---

# Python Project Rules

> Auto-loaded for `*.py` / `pyproject.toml` / `requirements.txt`.

## 1. Baseline

- Python 3.11+, `pyproject.toml` for deps (no `setup.py` in new projects)
- Package manager: **uv > poetry > pip-tools > pip**
- Virtualenv required (`.venv/` or conda) — no global site-packages installs
- Type hints mandatory on all signatures; `mypy --strict` or `pyright` clean
- Format: `ruff format` (replaces black)
- Lint: `ruff check` (replaces flake8/pylint/isort)

## 2. Naming

- Modules/files: `snake_case.py`
- Classes: `UpperCamelCase`
- Functions/variables: `snake_case`
- Constants: `SCREAMING_SNAKE_CASE`
- Private: `_internal`; double underscore only for real name mangling
- No abbreviations (`config` not `cfg`)

## 3. Type Annotations

- `dict`/`list`/`tuple` use builtin generics (PEP 585):
  ```python
  def f(items: list[str]) -> dict[str, int]: ...
  ```
  Not `from typing import Dict, List`
- `Optional[T]` → `T | None` (PEP 604)
- Multi-return: `NamedTuple` or `dataclass`, not 4+ element tuples
- `Any` is a cop-out — write a concrete type

## 4. Data Structures

| Scenario | Choice |
|---|---|
| External input (API/config) | `pydantic.BaseModel` |
| Internal data carrier | `@dataclass(frozen=True, slots=True)` |
| Dict-compat only | `TypedDict` |
| Simple return value | `NamedTuple` |

No bare dict as a data structure (unless it's a real key-value map).

## 5. Exceptions

- Custom exceptions inherit a specific base (`ValueError`/`RuntimeError`); never `Exception` directly
- `except` must handle or re-raise — no `except: pass` / `except Exception: pass`
- Resources via `with`; no manual `try/finally close`
- Custom exceptions live in `exceptions.py` or at module top

## 6. Async & Concurrency

- Async = `asyncio`; don't mix `threading` data structures in
- IO-bound → asyncio
- CPU-bound → `multiprocessing` or `ProcessPoolExecutor`
- No blocking IO in async funcs — wrap with `asyncio.to_thread()`
- `async def` must `await` — no fire-and-forget (unless `asyncio.create_task` is explicit)

## 7. Testing

- `pytest` over unittest
- Fixtures over setUp/tearDown
- Parameterize: `@pytest.mark.parametrize`
- Slow tests: `@pytest.mark.slow`; CI runs fast by default
- Names describe behavior: `test_login_with_expired_token_raises_auth_error`
- Mock with `pytest-mock`, not bare `unittest.mock`

## 8. Style

- Line width 100 (ruff default)
- Strings: `'` default, `"` when the string contains `'`
- Import order via ruff — don't hand-adjust
- f-strings over `.format()` / `%`
- No docstring templates ("This function does...") — write real info

## 9. Forbidden

- `from x import *`
- Mutable default args (`def f(x=[]):`)
- `+=` for strings in loops — use `''.join()`
- Bare `print` debug residue — use `logging`/debugger
- New dep without checking `pyproject.toml` for an equivalent
- Mixing `pathlib` and `os.path` — new code uses `pathlib`
- `eval`/`exec` on user input

## 10. Tool Priority

- Python symbol defs / call chains → codegraph_*; no grep
- Types uncertain → let `mypy`/`pyright` report, don't guess
