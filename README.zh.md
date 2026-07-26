# agent-rules

> English version: [README.md](./README.md). When modifying README, keep both versions in sync.

个人 agent 规则集 —— 跨机器、跨工具的 Claude Code（及其他 AGENTS.md 兼容工具）约束文件。

## 包含内容

- `AGENTS.md` — 通用硬规则（提交门禁、安全红线、沟通规范、工程纪律）。每次会话自动加载。
- `common/` — 通用工程规范（代码审查、开发流程、测试、编码风格、性能、安全、设计模式）。始终加载；并按场景主动引用。
- `rules/` — 语言 / 工具规则，按语言分目录，每个目录包含细分文件（coding-style、testing、patterns 等）。按文件类型加载。
- `install.sh` — 幂等安装器，含备份 + 卸载功能。

规则文件为英文；agent 默认用中文回复（见 AGENTS.md §4）。

## 快速安装（新机器）

```bash
# 1. 先安装 Claude Code（会创建 ~/.claude/）

# 2. 克隆仓库
git clone git@github.com:groot-guo/agent-rules.git
cd agent-rules

# 3. 预览后安装
bash install.sh --dry-run
bash install.sh

# 4. 重启 Claude Code
```

## install.sh 做了什么

1. 备份现有 `~/.claude/rules/`、`CLAUDE.md` 与 `AGENTS.md` → `~/.claude/.agent-rules-backup/`（仅首次运行）
2. 同步 `common/` + `rules/` 中受本项目管理的文件 → `~/.claude/rules/`；清理失效的受管文件与旧版平铺规则，不影响其他文件
3. 同步 `AGENTS.md` → `~/.claude/AGENTS.md`
4. 重写 `~/.claude/CLAUDE.md`：移除 `@SOUL/@RULES/@RTK`，加入 `@AGENTS.md`，**保留其余所有内容**（CodeGraph 块、自定义内容）

幂等 —— 可安全重复运行。CLAUDE.md 已接入则跳过。

## 卸载

```bash
bash install.sh --uninstall   # 恢复备份
```

## 验证

```bash
bash tests/install.sh
```

测试使用隔离的临时 Claude 目录，覆盖安装、旧规则清理、失效受管规则清理，以及卸载恢复。

## 不在安装范围内（需单独配置）

install.sh 只安装**规则文件**。以下内容不包含在内 —— 新机器上需要独立设置：

- **RTK** — 由 rtk 工具自行安装（hook 写入 `settings.json`）
- **codegraph** — MCP，按项目的 `.codegraph/` 索引
- **MCP 服务器** — `~/.claude.json`（base-admin、devops-admin、knowledge-vault 等）
- **settings.json** — model、env、permissions、hooks
- **skills** — `~/.agents/skills/`（独立的 lockfile）

## 目录结构

```
agent-rules/
├── AGENTS.md            # 入口，每次会话加载
├── CLAUDE.md -> AGENTS.md  # 符号链接，保持同步
├── common/              # 通用工程规范
│   ├── code-review.md
│   ├── dev-workflow.md
│   ├── testing.md
│   ├── coding-style.md
│   ├── performance.md
│   ├── security.md
│   └── patterns.md
├── rules/               # 语言 / 工具规则（按语言分目录）
│   ├── go/              # coding-style, testing, patterns
│   ├── python/          # coding-style, testing, patterns
│   ├── react/           # coding-style, testing, patterns, security
│   ├── typescript/      # coding-style, testing
│   ├── rust/            # coding-style, testing
│   ├── web/             # coding-style, patterns
│   ├── sql/             # coding-style
│   ├── shell/           # coding-style
│   ├── github.md        # GitHub 操作（跨领域）
│   └── gopls-upstream.md  # gopls 上游（项目特定）
├── install.sh
├── tests/install.sh       # 安装器回归测试
└── .github/workflows/test.yml
```

## 加载机制

- `AGENTS.md` — 强制加载（入口通过 `~/.claude/CLAUDE.md` → `@AGENTS.md`）
- `common/*.md` — 始终加载（通用标准，无条件）。同时按场景主动 Read（见 AGENTS.md §8）
- `rules/<lang>/` + `rules/*.md` — 语言目录通过 `paths:` frontmatter 按文件类型加载；平铺文件无条件加载。同时按文件类型主动 Read（见 AGENTS.md §7）

## 许可

个人使用。
