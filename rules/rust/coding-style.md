---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
---

# Rust Coding Style

> Naming, modules, types, errors, async. Extends `common/coding-style.md`.

## Baseline

- Rust 1.75+, edition 2021
- `cargo fmt --all` clean
- `cargo clippy --workspace --all-targets -- -D warnings` clean
- Public APIs need doc comments (`missing_docs` at least warn)
- Large projects split via Cargo workspace; single crate ≤ ~3000 lines

## Naming

| Category | Rule |
|---|---|
| crate | `lowercase-with-hyphens` (`lingxi-core`) |
| module/file | `snake_case` |
| type/trait/enum | `UpperCamelCase` |
| function/variable/field | `snake_case` |
| const/static | `SCREAMING_SNAKE_CASE` |
| type param | single uppercase or `UpperCamelCase` (`T`, `Ctx`) |

No abbreviations (`config` not `cfg`).

## Errors

**Lib (lib crate)** — `thiserror` enum:
```rust
#[derive(Debug, Error)]
pub enum Error {
    #[error("io at {path}: {source}")]
    Io { path: PathBuf, #[source] source: std::io::Error },
    ...
}
pub type Result<T> = std::result::Result<T, Error>;
```

**Binary (bin crate)** — `anyhow::Result<T>` + `.context("...")`

**Iron rules**:
- Libs never return `Box<dyn Error>` / `anyhow::Error`
- Binary main: `anyhow::Result<()>`
- `?` over unwrap/expect
- `unwrap()` only in tests or compile-time constants (`Regex::new("...").unwrap()`)

## Modules

- Private by default; `pub(crate)`/`pub(super)`/`pub` only when needed
- Re-export public APIs in `lib.rs` via `pub use` for short paths
- Single-file module: `xxx.rs`; multi-file: `xxx/mod.rs`

## Types

- **Newtype** wraps domain concepts — no bare `String`/`PathBuf` everywhere
- **enum** for state machines — make illegal states unrepresentable
- String params: `&str` to borrow, `String` to own
- Multi-return: struct/tuple struct, not `(A, B, C, D)`

## Async

- Binary: `#[tokio::main] async fn main()`
- Lib default sync; annotate explicitly when async is needed
- Public traits carry `Send + Sync` (trait objects cross threads)
- Don't hold std `Mutex` across await — use `tokio::sync::Mutex`
- IO async; CPU-bound → `tokio::task::spawn_blocking`

## Doc Comments

Public APIs:
```rust
/// One-line summary.
///
/// Details (optional).
///
/// # Errors
/// Failure scenarios.
///
/// # Examples
/// ```no_run
/// // example
/// ```
pub fn foo() -> Result<()> { ... }
```

Standard sections: `# Arguments` / `# Errors` / `# Panics` / `# Examples`.

## Dependencies

Selection criteria:
- Downloads > 1M/month
- Commits in last 6 months
- Trusted authors (BurntSushi, tokio-rs, rust-lang, dtolnay, ...)
- `cargo tree` to check transitive weight

Mainstream picks:
- CLI: clap (derive)
- async: tokio
- HTTP server: axum
- HTTP client: reqwest
- Errors: thiserror + anyhow
- Serde: serde + serde_json + toml
- Logging: tracing + tracing-subscriber

## Lint Config

workspace `Cargo.toml`:
```toml
[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.lints.clippy]
pedantic = { level = "warn", priority = -1 }
unwrap_used = "warn"
expect_used = "warn"
panic = "warn"
todo = "warn"
```

## Forbidden

- `unsafe` (project-level `unsafe_code = "forbid"`)
- `unwrap()`/`expect()`/`panic!()` in production paths
- `println!` debug residue — use `tracing::debug!`
- Commented-out code (git remembers)
- `Box<dyn Error>` in lib APIs
- `#[tokio::main]`/global state in lib crates
- Premature traits/generics for "future"
