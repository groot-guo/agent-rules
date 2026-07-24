# agent-rules

> English version: [README.md](./README.md). When modifying README, keep both versions in sync.

个人 agent 规则集 —— 跨机器、跨工具的 Claude Code（及其他 AGENTS.md 兼容工具）约束文件。

## 包含内容

- `AGENTS.md` — 通用硬规则（提交门禁、安全红线、沟通规范、工程纪律）。每次会话自动加载。
- `common/` — 通用工程规范（代码审查、开发流程、测试、编码风格、性能）。按场景加载。
- `rules/` — 语言 / 工具规则（go、python、rust、shell、sql、typescript、react、web、gopls-upstream、github）。按文件类型加载。
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

1. 备份现有 `~/.claude/rules/` + `CLAUDE.md` → `~/.claude/.agent-rules-backup/`（仅首次运行）
2. 同步 `common/` + `rules/` → `~/.claude/rules/`
3. 同步 `AGENTS.md` → `~/.claude/AGENTS.md`
4. 重写 `~/.claude/CLAUDE.md`：移除 `@SOUL/@RULES/@RTK`，加入 `@AGENTS.md`，**保留其余所有内容**（CodeGraph 块、自定义内容）

幂等 —— 可安全重复运行。CLAUDE.md 已接入则跳过。

## 卸载

```bash
bash install.sh --uninstall   # 恢复备份
```

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
│   └── performance.md
├── rules/               # 语言 / 工具规则
│   ├── go.md  python.md  rust.md  shell.md  sql.md
│   ├── typescript.md  react.md  web.md
│   └── gopls-upstream.md  github.md
└── install.sh
```

## 加载机制

- `AGENTS.md` — 强制加载（入口通过 `~/.claude/CLAUDE.md` → `@AGENTS.md`）
- `common/*.md` — 按场景主动 Read（见 AGENTS.md §8）
- `rules/*.md` — 按文件类型主动 Read（见 AGENTS.md §7）；含 `paths:` frontmatter 的语言文件也会自动加载

## 许可

个人使用。
