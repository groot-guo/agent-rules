# agent-rules

> 中文版见 [README.zh.md](./README.zh.md)。修改 README 时请同步更新两个版本。

Personal governance standards for coding agents, with room to extend to general-purpose autonomous agents such as OpenClaw.

This project keeps safety boundaries, user authorization, task scope, commit gates, and engineering collaboration principles in a tool-independent core, then installs them through adapters for Claude Code, Codex, and future agents. The current installer supports Claude Code first; cross-agent support describes the target architecture, not completed compatibility with every tool.

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

- `AGENTS.md` — universal hard rules (commit gate, security, communication, engineering discipline). Loaded every session.
- `guides/` — general engineering standards (code review, dev workflow, testing, coding style, performance, security, patterns) plus cross-cutting scenario guides (e.g. GitHub ops). Not auto-loaded; read on demand by scenario (AGENTS.md §7/§8).
- `rules/` — language/tool rules organized in per-language directories. Each directory contains focused files (coding-style, testing, patterns, etc.). Loaded by file type via `paths:` frontmatter.
- `install.sh` — entry point: detects installed coding agents and dispatches to adapters.
- `adapters/` — per-agent installers. `claude.sh` is implemented; others (codex, cursor) are planned.

Rules are in English; the agent responds in Chinese by default (see AGENTS.md §4).

## Quick install (new machine)

```bash
# 1. Install Claude Code first (creates ~/.claude/)

# 2. Clone
git clone git@github.com:groot-guo/agent-rules.git
cd agent-rules

# 3. Preview, then install
bash install.sh --dry-run
bash install.sh

# 4. Restart Claude Code
```

`install.sh` auto-detects installed agents. Force one with `--agent <name>` (e.g. `--agent claude`).

## What install.sh does

1. Detects installed coding agents (`~/.claude`, `~/.codex`, `~/.cursor`) and dispatches to each adapter. Use `--agent <name>` to force one.
2. The Claude adapter backs up existing `~/.claude/rules/`, `~/.claude/guides/`, `CLAUDE.md`, and `AGENTS.md` → `~/.claude/.agent-rules-backup/` (first run only)
3. Syncs `guides/` → `~/.claude/guides/` and `rules/` → `~/.claude/rules/`, removing obsolete managed files and legacy flat rules without touching unrelated files
4. Syncs `AGENTS.md` → `~/.claude/AGENTS.md`
5. Rewires `~/.claude/CLAUDE.md`: adds `@AGENTS.md` at the top, **preserves everything else** (existing `@` references, CodeGraph block, custom content)

Idempotent — safe to re-run. CLAUDE.md already wired → skipped.

## Uninstall

```bash
bash install.sh --uninstall   # restores backups
```

## Verification

```bash
bash tests/install.sh   # installer regression
bash tests/lint.sh      # rule file structure + route-table references
```

`tests/install.sh` uses an isolated temporary Claude directory and covers installation, legacy cleanup (flat rules, `rules/common/`, `rules/github.md`), stale managed-rule cleanup, and uninstall restoration. `tests/lint.sh` checks that every `rules/` file declares `paths:`, no `guides/` file does, and all `AGENTS.md` route-table references resolve.

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
│   ├── code-review.md
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
│   └── claude.sh        # Claude Code adapter (codex/cursor planned)
├── tests/
│   ├── install.sh       # installer regression tests
│   └── lint.sh          # rule file structure + route-table lint
├── .github/workflows/test.yml
└── README.zh.md         # 中文说明
```

## Loading mechanism

- `AGENTS.md` — force-loaded (entry via `~/.claude/CLAUDE.md` → `@AGENTS.md`). Contains the security red-line summary in §3.
- `rules/<lang>/*` + `rules/gopls-upstream.md` — auto-loaded by file type via `paths:` frontmatter (L1). Also proactively Read by file type (AGENTS.md §7).
- `guides/*.md` — NOT auto-loaded; read on demand by scenario (L2, AGENTS.md §7/§8). Keeps context lean.

## License

Personal use.
