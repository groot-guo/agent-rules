# agent-rules

Personal agent rules — cross-machine, cross-tool constraints for Claude Code (and other AGENTS.md-aware tools).

## What's inside

- `AGENTS.md` — universal hard rules (commit gate, security, communication, engineering discipline). Loaded every session.
- `common/` — general engineering standards (code review, dev workflow, testing, coding style, performance). Loaded by scenario.
- `rules/` — language/tool rules (go, python, rust, shell, sql, typescript, react, web, gopls-upstream, github). Loaded by file type.
- `install.sh` — idempotent installer with backup + uninstall.

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

## What install.sh does

1. Backs up existing `~/.claude/rules/` + `CLAUDE.md` → `~/.claude/.agent-rules-backup/` (first run only)
2. Syncs `common/` + `rules/` → `~/.claude/rules/`
3. Syncs `AGENTS.md` → `~/.claude/AGENTS.md`
4. Rewires `~/.claude/CLAUDE.md`: drops `@SOUL/@RULES/@RTK`, adds `@AGENTS.md`, **preserves everything else** (CodeGraph block, custom content)

Idempotent — safe to re-run. CLAUDE.md already wired → skipped.

## Uninstall

```bash
bash install.sh --uninstall   # restores backups
```

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
├── common/              # general engineering standards
│   ├── code-review.md
│   ├── dev-workflow.md
│   ├── testing.md
│   ├── coding-style.md
│   └── performance.md
├── rules/               # language/tool rules
│   ├── go.md  python.md  rust.md  shell.md  sql.md
│   ├── typescript.md  react.md  web.md
│   └── gopls-upstream.md  github.md
└── install.sh
```

## Loading mechanism

- `AGENTS.md` — force-loaded (entry via `~/.claude/CLAUDE.md` → `@AGENTS.md`)
- `common/*.md` — proactively Read by scenario (see AGENTS.md §8)
- `rules/*.md` — proactively Read by file type (see AGENTS.md §7); language files with `paths:` frontmatter may also auto-load

## License

Personal use.
