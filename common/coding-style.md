# General Coding Style

> Language-agnostic principles. Naming/formatting in `rules/<lang>.md`.

## Core

- **KISS** — simplest working solution; no premature optimization; clarity over cleverness
- **DRY** — extract repeated logic, but only when repetition is real (not speculative)
- **YAGNI** — no abstractions / config / flags for "the future" (AGENTS.md §5)

## Immutability First

New objects, not in-place mutation:
- Return new copies on modify
- Prevents hidden side effects; easier debug; safe concurrency

Language exceptions: Go pointer receivers, Rust `&mut` — follow idioms.

## Files

Many small > few large:
- High cohesion, low coupling
- 200–400 typical, 800 max
- By feature/domain, not by type
- Extract utilities from large modules

## Errors

- Explicit at every layer
- User-friendly outward; detailed logs inward
- No silent swallow (`_ = err` / `except: pass`) — AGENTS.md §5

## Input Validation

At system boundaries:
- All external input (user / API / file) validated before processing
- Schema validation (pydantic / serde / validator)
- Fail fast, clear messages
- Never trust external data

## Code Smells

- **Deep nesting**: > 4 levels → early return
- **Magic numbers**: named constants for thresholds/limits
- **Long functions**: > 50 lines → split
- **Long params**: > 4 → wrap in struct/object
