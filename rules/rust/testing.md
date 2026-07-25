---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
---

# Rust Testing

> Extends `common/testing.md`.

## Organization

- Unit tests at source bottom: `#[cfg(test)] mod tests { ... }`
- Integration tests in `tests/`
- `tempfile` for temp dirs, `pretty_assertions` for diffs
- Names describe behavior: `sync_with_conflict_returns_error`

## Patterns

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use pretty_assertions::assert_eq;

    #[test]
    fn parse_valid_input_returns_ast() {
        let input = "SELECT 1";
        let ast = parse(input).unwrap();
        assert_eq!(ast.statements.len(), 1);
    }

    #[test]
    fn parse_empty_input_returns_error() {
        let err = parse("").unwrap_err();
        assert!(matches!(err, Error::EmptyInput));
    }
}
```

## Coverage Targets

| Layer | Target |
|---|---|
| Pure utility / parser functions | ≥ 90% |
| Public API surface | ≥ 80% |
| Integration paths | Key flows covered |
