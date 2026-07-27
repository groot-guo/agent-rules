# agent-rules

> English version: [README.md](./README.md). When modifying README, keep both versions in sync.

面向 Coding Agent 的个人治理规范，并为 OpenClaw 等通用自主 Agent 预留扩展能力。

本项目将安全边界、用户授权、任务范围、提交门禁和工程协作原则维护为与具体工具解耦的核心规则，再通过适配层安装到 Claude Code、Codex 及后续支持的 Agent。当前安装器首先支持 Claude Code；"跨 Agent"是项目的目标架构，不代表所有工具均已完成适配。

## 目标

- **统一治理** — 在不同 Coding Agent、项目和机器间保持一致的授权、安全与协作原则
- **核心与适配分离** — 通用规则不绑定某个 Agent 的目录、命令或工具协议
- **渐进扩展** — 先支持 Coding Agent，再按实际需要接入 OpenClaw 等通用自主 Agent
- **项目优先** — 项目自身规范可以覆盖本项目的通用工程建议，但不能降低明确的安全边界
- **可审计、可回滚** — 安装内容和行为清晰，已有配置可以恢复

## 非目标

- 不提供 ECC 式的大型 Agent、Skill、Command 和 Hook 集合
- 不替代具体项目的架构、测试和编码规范
- 不假设所有 Agent 使用相同的配置格式或具备相同的工具能力
- 不声称尚未实现的 Agent 适配已经可用

## 包含内容

- `AGENTS.md` — 通用硬规则（提交门禁、安全红线、沟通规范、工程纪律）。每次会话自动加载。
- `guides/` — 通用工程规范（代码审查、开发流程、测试、编码风格、性能、安全、设计模式）及跨领域场景指南（如 GitHub 操作）。不自动加载；按场景按需 Read（AGENTS.md §7/§8）。
- `rules/` — 语言 / 工具规则，按语言分目录，每个目录包含细分文件（coding-style、testing、patterns 等）。通过 `paths:` frontmatter 按文件类型加载。
- `install.sh` — 入口：检测已安装的 Coding Agent 并分发到对应适配器。
- `adapters/` — 各 Agent 的安装器。`claude.sh` 已实现；其余（codex、cursor）待实现。

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

`install.sh` 自动检测已安装的 Agent。用 `--agent <name>`（如 `--agent claude`）强制指定单个。

## install.sh 做了什么

1. 检测已安装的 Coding Agent（`~/.claude`、`~/.codex`、`~/.cursor`）并分发到各适配器。用 `--agent <name>` 强制指定单个。
2. Claude 适配器备份现有 `~/.claude/rules/`、`~/.claude/guides/`、`CLAUDE.md` 与 `AGENTS.md` → `~/.claude/.agent-rules-backup/`（仅首次运行）
3. 同步 `guides/` → `~/.claude/guides/`、`rules/` → `~/.claude/rules/`；清理失效受管文件与旧版平铺规则，不影响其他文件
4. 同步 `AGENTS.md` → `~/.claude/AGENTS.md`
5. 改写 `~/.claude/CLAUDE.md`：在开头加入 `@AGENTS.md`，**保留其余所有内容**（现有的 `@` 引用、CodeGraph 块、自定义内容）

幂等 —— 可安全重复运行。CLAUDE.md 已接入则跳过。

## 卸载

```bash
bash install.sh --uninstall   # 恢复备份
```

## 验证

```bash
bash tests/install.sh   # 安装器回归
bash tests/lint.sh      # 规则文件结构与路由表引用校验
```

`tests/install.sh` 使用隔离的临时 Claude 目录，覆盖安装、旧规则清理（平铺规则、`rules/common/`、`rules/github.md`）、失效受管规则清理，以及卸载恢复。`tests/lint.sh` 检查：`rules/` 下文件必须声明 `paths:`、`guides/` 下文件不得声明 `paths:`、AGENTS.md 路由表引用的路径都能解析到仓库文件。

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
├── guides/              # L2：场景指南（不自动加载；经 §7/§8 按需 Read）
│   ├── code-review.md
│   ├── dev-workflow.md
│   ├── testing.md
│   ├── coding-style.md
│   ├── performance.md
│   ├── security.md
│   ├── patterns.md
│   └── github.md        # GitHub 操作（跨领域）
├── rules/               # L1：语言 / 工具规则（按语言分目录，paths: frontmatter）
│   ├── go/              # coding-style, testing, patterns
│   ├── python/          # coding-style, testing, patterns
│   ├── react/           # coding-style, testing, patterns, security
│   ├── typescript/      # coding-style, testing
│   ├── rust/            # coding-style, testing
│   ├── web/             # coding-style, patterns
│   ├── sql/             # coding-style
│   ├── shell/           # coding-style
│   └── gopls-upstream.md  # gopls 上游（paths: gopls/**）
├── install.sh           # 入口：检测 Agent + 分发
├── adapters/
│   └── claude.sh        # Claude Code 适配器（codex/cursor 待实现）
├── tests/
│   ├── install.sh       # 安装器回归测试
│   └── lint.sh          # 规则文件结构与路由表校验
├── .github/workflows/test.yml
└── README.zh.md         # 中文说明（本文件）
```

## 加载机制

- `AGENTS.md` — 强制加载（入口通过 `~/.claude/CLAUDE.md` → `@AGENTS.md`）。§3 含安全红线摘要。
- `rules/<lang>/*` + `rules/gopls-upstream.md` — 通过 `paths:` frontmatter 按文件类型自动加载（L1）。同时按文件类型主动 Read（AGENTS.md §7）。
- `guides/*.md` — 不自动加载；按场景按需 Read（L2，AGENTS.md §7/§8）。保持 context 精简。

## 许可

个人使用。
