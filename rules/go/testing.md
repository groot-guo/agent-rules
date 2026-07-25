---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---

# Go Testing

> Extends `common/testing.md`.

## Table-Driven Tests

Default pattern:

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

## Coverage Targets

| Layer | Target |
|---|---|
| Pure utility functions | ≥ 90% |
| Public API surface | ≥ 80% |
| Integration paths | Key flows covered |

## Benchmarking

```go
func BenchmarkParser(b *testing.B) {
    data := loadFixture(b, "large.sql")
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, _ = Parse(data)
    }
}
```

- Reset timer after setup
- Report `ns/op` + `allocs/op`
- Compare with `benchstat` for significance
