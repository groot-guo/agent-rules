# Design Patterns

> Language-agnostic architecture patterns for AI-assisted development.
> Language idioms in `rules/<lang>.md`.

## Skeleton Projects

Start new features from proven templates, not from scratch:
- Search for battle-tested skeleton/boilerplate in the target stack first
- Evaluate candidates on: security, extensibility, relevance, maintenance
- Clone best match, iterate within its structure
- Avoid reinventing project layout, auth, config loading, logging setup

## Repository Pattern

Encapsulate data access behind a consistent interface:
- `findAll(filter)` / `findById(id)` / `create(entity)` / `update(entity)` / `delete(id)`
- Concrete implementations handle storage details (DB, API, file)
- Business logic depends on the abstract interface only
- Enables swapping data sources and simplifying tests with mocks

## API Response Format

Consistent envelope for all API responses:
```json
{
  "success": true,
  "data": {},
  "error": null,
  "meta": { "total": 100, "page": 1, "limit": 20 }
}
```
- `success` — boolean status indicator
- `data` — payload, null on error
- `error` — message, null on success
- `meta` — pagination / cursor, omit if not list

## Error Handling

Layered error strategy:
- **Boundary layer** (HTTP handler / CLI / gRPC) — catch all, translate to user-friendly response
- **Service layer** — domain errors only, no raw DB/IO errors leaked
- **Data layer** — wrap storage errors with context (what was being queried)
- No `catch (Exception)` / `except:` swallow anywhere

## Dependency Direction

- High-level policy → depends on → low-level detail, through abstractions
- No circular imports across packages/modules
- Config / secrets injected, not read from global state
- Test with real implementations where practical; stub external IO only
