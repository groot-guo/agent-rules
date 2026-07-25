---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/requirements.txt"
---

# Python Patterns

> Exceptions, async, and idiomatic patterns. Extends `common/patterns.md`.

## Exceptions

- Custom exceptions inherit a specific base (`ValueError`/`RuntimeError`); never `Exception` directly
- `except` must handle or re-raise — no `except: pass` / `except Exception: pass`
- Resources via `with`; no manual `try/finally close`
- Custom exceptions live in `exceptions.py` or at module top

```python
class UserNotFoundError(ValueError):
    """Raised when a user lookup by ID returns nothing."""
    def __init__(self, user_id: int):
        super().__init__(f"User not found: id={user_id}")
        self.user_id = user_id
```

## Async & Concurrency

- Async = `asyncio`; don't mix `threading` data structures in
- IO-bound → asyncio
- CPU-bound → `multiprocessing` or `ProcessPoolExecutor`
- No blocking IO in async funcs — wrap with `asyncio.to_thread()`
- `async def` must `await` — no fire-and-forget (unless `asyncio.create_task` is explicit)

```python
# Correct: async gather
async def fetch_all(ids: list[int]) -> list[User]:
    tasks = [fetch_user(id) for id in ids]
    return await asyncio.gather(*tasks)

# Correct: offload blocking IO
async def read_config(path: Path) -> Config:
    raw = await asyncio.to_thread(path.read_text)
    return Config.model_validate_json(raw)
```
