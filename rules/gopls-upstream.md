---
paths:
  - gopls/go.mod
  - gopls/internal/**
---

# gopls / Go Upstream Contribution Rules

> Auto-loaded for `gopls/` paths or `go-review.googlesource.com` CLs.
> gopls / Go upstream repo contributions only — not general Go conventions.

## 1. gopls Mechanisms

- **Separate module**: `gopls/` has its own `go.mod` — use `go -C gopls <cmd>`; `./gopls/...` from root errors "does not contain package"
- **Marker tests**: `gopls/internal/test/marker`, testdata by feature (highlight/definition/hover/references/…); `.txt` uses `-- file --` blocks + `//@hiloc`/`//@highlightall`/`//@highlight` annotations. Run: `go -C gopls test ./internal/test/marker/ -run 'Test/<feature>[/<file>]'`
- **Shared code → full marker chain**: e.g. `resolve.go` backs Definition/Hover/References — changing it runs all three features' asm markers, not just the one touched
- **`protocol.Mapper.Content []byte` is public**: read `f.Mapper.Content` directly for raw content — don't thread it through params or re-read the file
- **asm layering**: `gopls/internal/util/asm` (parser, no LSP) + `gopls/internal/goasm` (LSP features). New methods go in `util/asm` first so highlight/resolve/hover/references share them
- **GOARCH-gate arch-specific logic**: x86-only (mnemonic sets, operand direction) — either GOARCH-gate (amd64/386 only) or comment as x86-only, with test coverage
- **`event.Start` tracing**: handler entry `ctx, done := event.Start(ctx, "goasm.Highlight"); defer done()`
- **`protocol.Mapper` for offset↔range**: `RangeOffsets(rng)` / `OffsetRange(lo, hi)` / `OffsetLocation` — don't compute row/col by hand
- **TODO carries an issue**: `// TODO(golang/go#NNN): ...` (extends `TODO(name)`; Go upstream convention)
- **`internal` is sealed**: `gopls/internal/...` never exposed; cross-package reuse goes through `util/`

## 2. Go Upstream / Gerrit

- **Trailer semantics**: `Fixes #NNN` auto-closes the issue — only when the CL fully resolves it. Multi-feature issues → `For #NNN` (Alan's preference) or `Updates #NNN`. See go.dev/doc/contribute#commit_messages
- **Body line width**: ≤ ~76 chars (except URLs/tables) — Gopher Robot checks
- **Don't amend-push**: GerritBot syncs commit message from the GitHub PR title + description. Edit the PR title/first description in the GitHub web UI, not local amend
- **Release notes**: new features add an entry in `gopls/doc/release/vX.Y.0.md` under the right section (Editing/Analysis features…) — reviewers will ask
- **Review replies**: `Done` or explain every comment; pure praise ("very nice") needs no reply; food-for-thought → say if done + why; unclear semantics → ask, don't change literally
- **Login to reply**: author logs in to go-review with Google account to mark Done + Reply per comment — otherwise replies are self-only
- **CL ↔ PR**: one Gerrit CL = one GitHub PR (GerritBot syncs both ways); push via PR

## 3. Gerrit REST API

go-review pages are JS-rendered — WebFetch can't get the body. Use REST:

- **Change messages** (Patch Set summaries): `GET /changes/{id}/messages/`
- **Inline file comments** (by file dict): `GET /changes/{id}/comments/`
- Responses start with `)]}'` (XSSI guard) — strip first 4 bytes before JSON parse
- `{id}`: number (`804760`) or `project~branch~Change-Id`
- Public CL comments/messages are anonymous-readable — no token
