---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---

# Go Project Rules

> Auto-loaded for `*.go` / `go.mod`. Go conventions + gRPC specifics.

## 1. Baseline

- Go 1.21+, modules mode (no GOPATH projects)
- `gofmt` + `goimports` clean
- `go vet ./...` warning-free
- `golangci-lint run` passes (honors `.golangci.yml` if present)
- After editing proto, regenerate stubs: `make proto` or `buf generate`

## 1.1 go.mod / go.sum Conflicts

On merge/rebase conflicts:

1. Resolve `go.mod` by hand — keep both sides' require/replace lines, take the higher version (or per business need)
2. Never hand-resolve `go.sum` — `git checkout --theirs go.sum` or delete it
3. Run `go mod tidy` at repo root to recompute `go.sum` and prune indirect deps
4. `go build ./...` to verify
5. `git add go.mod go.sum && git commit` (or `git rebase --continue`)

**Don't**:
- Hand-diff `go.sum` — hashes can't be reconciled manually
- `go mod download` then commit — doesn't fix version mismatch
- Run `go mod tidy` with `<<<<<<<` markers left — Go refuses

**If `go mod tidy` fails** (version unreachable):
- Find the failing module → check its version in `go.mod`
- Private repo → verify `GOPRIVATE` / `GONOSUMCHECK`
- Don't downgrade versions just to make tidy pass — report to user first

## 2. Naming & Doc Comments

- Packages: `lowercase`, singular, no underscores/camelCase (`user` not `users`)
- Exported `UpperCamelCase`, private `lowerCamelCase`
- Single-method interfaces end `-er` (`Reader`, `Closer`, `Stringer`)
- Errors: `ErrXxx` variables, `XxxError` types
- Tests: `xxx_test.go`, `TestXxx` / `BenchmarkXxx` / `ExampleXxx`
- Exported/cross-scope names: no abbreviations (`config` not `cfg`); short local scope allows idiomatic short names (`mn`, `i`, `id`)
- Range bounds: `lo, hi` for half-open `[lo, hi)`
- Exported symbols need doc starting with the symbol name; one-line summary, blank `//`, then details/examples (`// e.g. "AX" in "MAX"`)
- `TODO` carries an owner: `// TODO(name): ...`

## 3. Interfaces & Dependencies

- Define interfaces in the consumer package, not the implementor
- Prefer single-method interfaces (compose well)
- No `var _ Foo = (*Bar)(nil)` assertion unless externally required
- Don't pre-extract for "future" — only when ≥ 2 implementations exist
- Sink bookkeeping/boundary logic into the data layer or parser as type methods; don't duplicate per call site
- Prefer `&f.Idents[idx]` over `&id` in range loops — avoids copy and the loop-variable capture trap

## 4. Errors

- Inspect with `errors.Is` / `errors.As`; no type assertion + comparison
- Wrap: `fmt.Errorf("doing X: %w", err)`; `pkg/errors` deprecated, don't use
- No `_ = err` unless a comment explains why
- No `panic` in business paths — only `init` or invariant violations
- Messages lowercase, no trailing period (`errors.New("not found")` not `"Not found."`)

## 5. Context

- `ctx context.Context` is the first parameter
- Don't store context in struct fields
- Client calls need a timeout: `context.WithTimeout(ctx, ...)` — no bare ctx to remotes
- Don't relay with `context.Background()` unless truly top-level
- `context.WithValue` only for cross-cutting concerns (trace, auth), never business params

## 6. Control Flow

- Early return over deep if-else
- `defer` right after resource acquisition, not piled at function end
- Pre-allocate slices: `make([]T, 0, n)` when size is known
- No defensive nil checks — internal funcs trust upstream-validated params
- No `+=` for strings in loops — `strings.Builder`
- Range checks in positive form, variable centered: `!(lo <= x && x < hi)` not `x < lo || hi <= x`; chars `'A' <= c && c <= 'Z'` not `c >= 'A' && c <= 'Z'` — inclusivity readable at a glance
- Multi-condition `&&`: cheap + selective checks first (e.g. int Kind before string Name)
- Clamp with `min`/`max`: `min(max(x, lo), hi)`, not two ifs (Go 1.21+)
- `for i := range n` over `for i := 0; i < n; i++` (Go 1.22+)
- Skip intermediate bool vars — if you can break/return in the condition, don't add `isXxx`

## 7. Concurrency

- Sender closes channels, not receiver
- No channels for "signal notification" — use `context.Done()` or `sync.WaitGroup`
- Every goroutine needs a clear exit path — never spawn one that can't be reclaimed
- Shared state: `sync.RWMutex` / `sync.Mutex`; atomic only for simple counters
- No `time.Sleep` for synchronization — use channel / cond / wg

## 8. Testing

- Table-driven by default:
  ```go
  tests := []struct{
      name string
      in   X
      want Y
      err  error
  }{...}
  for _, tt := range tests {
      t.Run(tt.name, func(t *testing.T) { ... })
  }
  ```
- `testify/require` for hard assertions (fail-stop), `testify/assert` for accumulated
- Integration tests don't mock the DB — real testdb or docker
- Benchmarks report `ns/op` + `allocs/op`; no regressions
- Test names describe behavior: `TestUser_Login_WithExpiredToken_ReturnsAuthError`

## 9. gRPC

- Server interceptor order: recovery → metrics → tracing → auth → business
- Client calls carry a timeout: `ctx, cancel := context.WithTimeout(ctx, 3*time.Second); defer cancel()`
- Return errors via `status.Errorf(codes.X, "...")` — not raw Go errors
- Proto fields `snake_case`; Go struct fields auto-`UpperCamelCase`
- Streams handle both EOF and ctx cancellation
- Mixed CN-EN comments (Chinese description + English terms); upstream contributions are all-English and override this. Exhaustive-comment scenarios trigger the `code-comments` skill

## 10. Performance & Resources

- No `reflect` / `fmt.Sprintf` in hot paths — use `strconv` / `strings.Builder`
- Large by pointer, small by value (< ~64 bytes)
- No `defer` in loops — accumulates until function end
- Pre-allocate maps: `make(map[K]V, n)`
- 3+ string segments → `strings.Builder`, not `+=`
- Sorted data → binary search (`sort.Search`), encapsulated as a type method; no linear scan
- `bytes.Contains(s, sub)` not `bytes.Index(s, sub) >= 0` — same for `strings`
- Lazy single-point checks (e.g. `inComment(offset)`) over `make+copy` of a range
- Fixed-pattern word match → `bytes.Index` + boundary check, not `regexp.MustCompile` (compile cost)

## 11. Tool Priority (with codegraph index)

- Go symbol defs / call chains / impact → codegraph_* mandatory; no grep+read
- Before changing an interface/public func → `codegraph_impact`
- Before refactoring → `codegraph_callers`

## 12. Forbidden

- `_ = err` silent errors (unless commented)
- New dependency without checking `go.mod` for an equivalent
- Refactoring code unrelated to the task
- Abstractions / config / feature flags for "the future"
- `fmt.Println` debug residue in prod (use log)
- Vendoring third-party code (unless already vendored)
