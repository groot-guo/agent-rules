# agent-rules

> 中文版见 [README.zh.md](./README.zh.md)。修改 README 时请同步更新两个版本。

Personal governance standards for coding agents, with room to extend to general-purpose autonomous agents such as OpenClaw.

This project keeps safety boundaries, user authorization, task scope, commit gates, and engineering collaboration principles in a tool-independent core, then installs them through adapters for Claude Code, Codex, and future agents. The current installer supports Claude Code and Codex; other agents remain planned.

## Goals

- **Consistent governance** — preserve the same authorization, safety, and collaboration principles across coding agents, projects, and machines
- **Separate core from adapters** — keep universal rules independent of any agent's directories, commands, or tool protocol
- **Expand incrementally** — support coding agents first, then add general-purpose autonomous agents such as OpenClaw when needed
- **Project precedence** — allow project-specific standards to override general engineering guidance without weakening explicit safety boundaries
- **Auditable and reversible** — make installed content and behavior clear, with recovery for existing configuration

## Non-goals

- Providing an ECC-style catalog of agents, skills, commands, and hooks
- Replacing project-specific architecture, testing, or coding standards
- Assuming every agent uses the same configuration format or exposes the same tool capabilities
- Claiming support for an agent before its adapter is implemented

## What's inside

- `AGENTS.md` — compact universal guardrails (explicit commits, safety, scope, and communication). Loaded every session.
- `guides/` — general engineering guidance (dev workflow, testing, coding style, performance, security, patterns) plus cross-cutting scenario guides (e.g. GitHub ops). Read on demand; they are not automatic gates (AGENTS.md §7/§8).
- `rules/` — language/tool rules organized in per-language directories. Claude Code can load them by file type via `paths:` frontmatter; Codex reads them on demand through the route table installed in its global `AGENTS.md` block.
- `install.sh` — entry point: detects installed coding agents and dispatches to adapters.
- `adapters/` — per-agent installers. `claude.sh` and `codex.sh` are implemented; Cursor is planned.

Rules are in English; the agent responds in Chinese by default (see AGENTS.md §4).

## Quick install (new machine)

```bash
# 1. Install Claude Code and/or Codex first
#    (creates ~/.claude/ and/or ~/.codex/)

# 2. Clone
git clone git@github.com:groot-guo/agent-rules.git
cd agent-rules

# 3. Preview, then install
bash install.sh --dry-run
bash install.sh

# 4. Restart the installed coding agents
```

`install.sh` auto-detects installed agents. Force one with `--agent <name>` (e.g. `--agent claude`).

## What install.sh does

1. Detects installed coding agents (`~/.claude`, `~/.codex`, `~/.cursor`) and dispatches to each adapter. Use `--agent <name>` to force one.
2. The Claude adapter backs up existing `~/.claude/rules/`, `~/.claude/guides/`, `CLAUDE.md`, and `AGENTS.md` → `~/.claude/.agent-rules-backup/` (first run only)
3. The Claude adapter syncs detailed content into `~/.claude/{rules,guides}/`, syncs a Claude-rendered `AGENTS.md`, and adds `@AGENTS.md` to `CLAUDE.md` while preserving its other content
4. The Codex adapter syncs detailed content into the isolated `~/.codex/agent-rules/{rules,guides}/` namespace; it does not write to Codex's own `~/.codex/rules/`
5. The Codex adapter maintains one marked block in `~/.codex/AGENTS.md`, preserving all user content outside that block and resolving path/review-suggestion placeholders for the Codex namespace
6. Both adapters remove only stale files from their managed manifests

Idempotent — safe to re-run. Codex installation fails closed if its managed markers are malformed or its payload namespace already exists without a managed manifest.

## Uninstall

```bash
bash install.sh --uninstall   # restores/removes only adapter-managed content
```

## Verification

```bash
bash tests/install.sh   # installer regression
bash tests/codex-install.sh   # Codex adapter lifecycle
bash tests/lint.sh      # rule file structure + route-table references
```

`tests/install.sh` uses an isolated temporary Claude directory and covers installation, legacy cleanup, stale managed-rule cleanup, and uninstall restoration. `tests/codex-install.sh` uses an isolated Codex directory and covers managed-block merging, path adaptation, namespace isolation, stale cleanup, dry-run, conflicts, and uninstall preservation. `tests/lint.sh` checks that every `rules/` file declares `paths:`, no `guides/` file does, `AGENTS.md` uses resolvable placeholders, and both Claude and Codex rendered variants are placeholder-free with only their own review route.

## Out of scope (configure separately)

install.sh only installs **rules**. These are not included — set them up independently on a new machine:

- **RTK** — installed by the rtk tool itself (hook in `settings.json`)
- **codegraph** — MCP, per-project `.codegraph/` index
- **MCP servers** — `~/.claude.json` (base-admin, devops-admin, knowledge-vault, etc.)
- **settings.json** — model, env, permissions, hooks
- **skills** — `~/.agents/skills/` (separate lockfile)

## Structure

```
agent-rules/
├── AGENTS.md            # entry, loaded every session
├── CLAUDE.md -> AGENTS.md  # symlink, stays in sync with AGENTS.md
├── guides/              # L2: scenario guides (not auto-loaded; read via §7/§8)
│   ├── dev-workflow.md
│   ├── testing.md
│   ├── coding-style.md
│   ├── performance.md
│   ├── security.md
│   ├── patterns.md
│   └── github.md        # GitHub ops (cross-cutting)
├── rules/               # L1: language/tool rules (per-language dirs, paths: frontmatter)
│   ├── go/              # coding-style, testing, patterns
│   ├── python/          # coding-style, testing, patterns
│   ├── react/           # coding-style, testing, patterns, security
│   ├── typescript/      # coding-style, testing
│   ├── rust/            # coding-style, testing
│   ├── web/             # coding-style, patterns
│   ├── sql/             # coding-style
│   ├── shell/           # coding-style
│   └── gopls-upstream.md  # gopls upstream (paths: gopls/**)
├── install.sh           # entry: detect agents + dispatch
├── adapters/
│   ├── claude.sh        # Claude Code adapter
│   └── codex.sh         # Codex adapter
├── lib/
│   └── render-agents.sh # shared AGENTS.md placeholder/route renderer
├── docs/
│   └── codex-adapter-design.md
├── tests/
│   ├── install.sh       # installer regression tests
│   ├── codex-install.sh # Codex adapter lifecycle tests
│   └── lint.sh          # rule file structure + route-table lint
├── .github/workflows/test.yml
└── README.zh.md         # 中文说明
```

## Loading mechanism

- `AGENTS.md` — Claude loads the synced file through `~/.claude/CLAUDE.md` → `@AGENTS.md`; Codex loads a managed copy embedded in `~/.codex/AGENTS.md`. Contains the security red-line summary in §3.
- The source `AGENTS.md` uses `{{RULES_DIR}}`/`{{GUIDES_DIR}}` path placeholders and per-agent review-suggestion blocks; each adapter resolves them at install time (Claude → `~/.claude/{rules,guides}`, Codex → `~/.codex/agent-rules/{rules,guides}`). Review is opt-in: agents recommend it before a code commit but do not start it automatically.
- Codex loads instructions in merge order: global `~/.codex/AGENTS.md` first, then project-root and nested `AGENTS.md` files; files closer to the working directory come later and take precedence. A non-empty `~/.codex/AGENTS.override.md` shadows the managed global file, so the adapter fails closed on install.
- `rules/<lang>/*` + `rules/gopls-upstream.md` — Claude can auto-load them by file type via `paths:` frontmatter (L1). Codex reads only the relevant file for the task through AGENTS.md §7: coding style for edits, tests for test work, and patterns/security only when applicable.
- `guides/*.md` — read on demand by scenario (L2, AGENTS.md §7/§8). This keeps context lean.

The Codex adapter's constraints, merge algorithm, rollback boundary, and acceptance tests are documented in [`docs/codex-adapter-design.md`](./docs/codex-adapter-design.md).

## License

Personal use.
