---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---

# Go Patterns

> Concurrency, gRPC, and idiomatic Go patterns. Extends `common/patterns.md`.

## Concurrency

- Sender closes channels, not receiver
- No channels for "signal notification" — use `context.Done()` or `sync.WaitGroup`
- Every goroutine needs a clear exit path — never spawn one that can't be reclaimed
- Shared state: `sync.RWMutex` / `sync.Mutex`; atomic only for simple counters
- No `time.Sleep` for synchronization — use channel / cond / wg

### Common Patterns

```go
// Worker pool
func worker(ctx context.Context, jobs <-chan Job, results chan<- Result) {
    for {
        select {
        case <-ctx.Done():
            return
        case job, ok := <-jobs:
            if !ok { return }
            results <- process(job)
        }
    }
}

// Errgroup for parallel tasks with error propagation
g, ctx := errgroup.WithContext(ctx)
g.Go(func() error { return fetchA(ctx) })
g.Go(func() error { return fetchB(ctx) })
if err := g.Wait(); err != nil { ... }
```

## gRPC

- Server interceptor order: recovery → metrics → tracing → auth → business
- Client calls carry a timeout: `ctx, cancel := context.WithTimeout(ctx, 3*time.Second); defer cancel()`
- Return errors via `status.Errorf(codes.X, "...")` — not raw Go errors
- Proto fields `snake_case`; Go struct fields auto-`UpperCamelCase`
- Streams handle both EOF and ctx cancellation
