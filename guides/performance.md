# Performance Standards

> Use for performance-sensitive changes or a reported performance issue. Language specifics are in `rules/<lang>/`.

## General

- Measure before optimizing (profile-driven)
- Optimize hot paths only; readability on cold paths
- Correctness + tests before optimization

## Database

- **N+1**: DB calls in loops → JOIN / batch / IN
- **Pagination**: list queries need LIMIT / keyset
- **Unbounded**: `SELECT *` without WHERE/LIMIT → add constraints
- **Index**: WHERE / ORDER BY fields indexed
- Large changes → batch, not all at once

## Caching

- Cache expensive computations
- Invalidation strategy — avoid stale data
- Read-heavy write-light suits caching

## Loops / Data Structures

- Hoist IO / computation out of loops
- Pre-allocate when size known (slice / map / list)
- Builder for large string concat (not `+=`)
- Binary search on sorted data, not linear scan

## Concurrency

- IO-bound → concurrency / async
- CPU-bound → parallelism (≤ CPU cores)
- Mind lock granularity — avoid hot-path contention

## Resources

- Release when done (defer / with / RAII)
- No defer/release accumulating in loops
- Large by pointer, small by value (< ~64 bytes)
