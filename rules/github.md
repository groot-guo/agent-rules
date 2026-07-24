---
paths:
  - .git/**
---

# GitHub / External Platform Rules

> Auto-loaded for any git repo. `paths:` can only match file paths,
> not git remote URLs — `.git/**` is the closest proxy.
> Cross-project, language-agnostic.

## 1. API First, Don't Scrape JS Pages

- GitHub/Gerrit/GitLab pages are JS-rendered — WebFetch-to-markdown gets only headers/shells
- GitHub → `gh api`/`gh pr`/`gh issue`; Gerrit → REST API (see `gopls-upstream.md`); GitLab → `glab` or API
- WebFetch only for pure static HTML

## 2. Prefer `gh` CLI

- PR/issue/repo/release/workflow ops → `gh`; no WebFetch, no hand-crafted curl
- Subcommands first: `gh pr view`/`gh issue list`/`gh pr create` beat `gh api`
- `gh api graphql` or `gh api repos/...` only for specific fields

## 3. commit message Edits

- Squash-merge message = PR title + first description — edit the PR (GitHub web Edit), don't local amend + force-push
- Amend + force-push bypasses PR history and protected branches may reject; GerritBot sync same (see `gopls-upstream.md`)
- Editing PR title/description → sync tools regenerate the message

## 4. Trailer Semantics

- `Fixes #NNN`/`Closes #NNN` auto-close on merge — only when the PR fully resolves the issue
- Multi-part work → `Updates #NNN` or `For #NNN` (no auto-close)
- Trailers at commit body end, one per line

## 5. Backticks / Special Chars via CLI

- `--content "$(cat file)"` — backticks inside double quotes trigger shell command substitution, corrupting markdown
- Use python `subprocess` list args (no shell), or stdin/`@file` when supported
- Same for `$`, `!`, `` ` `` — no double-quoted `$(cat)`

## 6. WebFetch Down → Fallback

- Classifier down? Public read-only APIs → `curl` + `python3 -c`/`jq` directly; don't wait
- Auth APIs → `gh api` (carries token); never put tokens in commands or code
