# Codex Adapter 设计说明

## 1. 背景与定位

当前安装入口已经能够检测 `~/.codex/`，但仓库缺少 `adapters/codex.sh`，因此检测到 Codex 后会以未实现状态退出。与此同时，核心 `AGENTS.md` 的详细规则路径仍指向 `~/.claude/`，不能直接复制到 Codex 全局目录。

本设计为 Codex 增加独立 adapter，使通用 hard rules 能在其他项目中全局生效，同时保留用户已有的 Codex instructions，并让详细语言规则与工程指南继续按需加载。

## 2. 目标

| 目标 | 说明 |
|---|---|
| 全局生效 | 将通用 hard rules 接入 `~/.codex/AGENTS.md` |
| 内容隔离 | 将详细规则安装到 `~/.codex/agent-rules/`，不占用 Codex 自身目录语义 |
| 保留用户配置 | 不覆盖 `~/.codex/AGENTS.md` 中的既有内容 |
| 幂等更新 | 重复安装只替换受管内容，不产生重复 block |
| 可回滚 | 卸载只移除 adapter 管理的内容，保留用户后续修改和非受管文件 |
| 可验证 | 支持隔离目录测试，不访问真实 `~/.codex/` |

## 3. 非目标

Codex adapter 只安装规则文件，不负责以下内容：

- 不修改 `~/.codex/config.toml`、`requirements.toml`、model 或 sandbox 配置。
- 不安装或修改 hooks、MCP servers、plugins、skills、automations。
- 不管理 Codex command rules 或 approval policies。
- 不让 Codex 解释 Claude Code 的 `paths:` frontmatter；该 frontmatter 在 Codex 中仅作为文件内容保留。
- 不创建指向本仓库 clone 路径的符号链接，避免移动仓库后失效。
- 不改变 Claude adapter 的现有安装行为。

## 4. 核心约束

### 4.1 目录隔离

Codex 的详细规则不得写入 `~/.codex/rules/`。该路径可能用于 Codex 自身的 command rules，混入 Markdown 语言规则会造成概念冲突和未来兼容风险。

adapter 使用以下独立 namespace：

```text
~/.codex/
├── AGENTS.md
├── .agent-rules-managed
└── agent-rules/
    ├── rules/
    │   ├── go/
    │   ├── python/
    │   └── ...
    └── guides/
        ├── code-review.md
        ├── testing.md
        └── ...
```

### 4.2 AGENTS.md 合并边界

adapter 在 `~/.codex/AGENTS.md` 中维护唯一 block：

```markdown
<!-- AGENT_RULES_START -->
<!-- Managed by agent-rules/adapters/codex.sh. -->
...
<!-- AGENT_RULES_END -->
```

合并规则：

1. 文件不存在时创建文件并写入 managed block。
2. 文件存在且没有 marker 时，将 managed block 放在文件开头，原内容逐行保留。
3. 文件存在且有一组合法 marker 时，只替换 marker 内部内容。
4. marker 缺失、重复或顺序错误时立即失败，不修改文件。
5. 写入通过同目录临时文件加原子 `mv` 完成，避免生成半写文件。

### 4.3 路径适配

仓库根 `AGENTS.md` 是 hard rules 的唯一来源。安装时只执行以下路径映射，不维护第二份规则副本：

| 源路径 | Codex 安装路径 |
|---|---|
| `~/.claude/rules/` | `~/.codex/agent-rules/rules/` |
| `~/.claude/guides/` | `~/.codex/agent-rules/guides/` |

除上述路径前缀外，adapter 不改写规则文本。

### 4.4 受管文件边界

`.agent-rules-managed` 记录 adapter 上一次安装的 `rules/` 与 `guides/` 相对路径。

- 更新时只删除 manifest 中已记录、但仓库中已经不存在的 stale 文件。
- 卸载时只删除 manifest 中记录的文件。
- 用户放在 `agent-rules/` 下但未写入 manifest 的文件必须保留。
- 如果首次安装前 `agent-rules/` 已存在但没有 manifest，adapter 必须失败，避免接管来源不明的目录。
- 空目录使用 `rmdir` 清理，不使用递归强制删除。

## 5. 加载模型

```text
Codex 启动或进入项目
        │
        ├── 读取项目层级 AGENTS.md
        │
        └── 读取 ~/.codex/AGENTS.md
                    │
                    ├── 应用 Universal Hard Rules
                    │
                    └── 按文件类型或任务场景
                         主动读取 ~/.codex/agent-rules/{rules,guides}/...
```

项目根目录已经存在 `AGENTS.md` 时，当前项目无需依赖全局同步即可获得项目规则。Codex adapter 解决的是跨项目、跨机器安装后的全局一致性。

Codex 不依赖 Claude Code 的 `paths:` 自动加载机制。详细规则是否读取，由全局 hard rules 中的 Language Rules Index 和 General Engineering Standards 明确触发。

## 6. 安装流程

1. 校验 `REPO`、`CODEX_DIR` 和运行参数。
2. 确认 `CODEX_DIR` 已存在。
3. 校验现有 `AGENTS.md` marker 完整性和 manifest 路径安全性。
4. 检查 `agent-rules/` namespace 是否存在未受管冲突。
5. `--dry-run` 到此为止，只输出计划，不写文件。
6. 同步仓库 `rules/` 与 `guides/` 到独立 namespace。
7. 根据旧 manifest 清理 stale managed files，并原子更新 manifest。
8. 渲染 Codex 路径并原子合并 `AGENTS.md` managed block。

安装失败后不得静默绕过。输出必须说明失败对象和已知原因，用户可修复冲突后重复运行安装命令。

## 7. 卸载流程

1. 校验 `AGENTS.md` marker 和 manifest 路径；任一异常时停止，避免误删用户内容。
2. 从 `AGENTS.md` 中移除 managed block，保留 block 外全部内容。
3. 如果移除后文件为空，则删除由 adapter 创建的空文件。
4. 根据 manifest 删除受管规则文件。
5. 删除 manifest，并用 `rmdir` 清理已经为空的受管目录。
6. 保留所有未受管文件和 Codex 其他配置。

## 8. Dry-run 行为

`bash install.sh --agent codex --dry-run` 必须：

- 展示目标 `CODEX_DIR`、规则目录、manifest 和 `AGENTS.md` 操作。
- 执行只读 preflight，能够报告 marker 或 namespace 冲突。
- 不创建目录、临时文件、manifest 或 managed block。

## 9. 测试与验收标准

测试通过 `CODEX_DIR=<temp-dir>` 注入隔离目录，不读取或修改真实用户配置。

必须覆盖：

1. 首次安装能够同步 `rules/`、`guides/` 并创建 manifest。
2. 原有 `AGENTS.md` 内容完整保留。
3. 安装结果包含 Codex 路径，不再包含 `~/.claude/rules/` 或 `~/.claude/guides/`。
4. 重复安装后 START/END marker 各只有一个。
5. stale managed file 在重装时被删除。
6. `~/.codex/rules/` 中模拟的 command rule 保持不变。
7. 卸载移除 managed block 与受管文件，保留用户 instructions 和非受管文件。
8. 空目录安装再卸载后不遗留 `AGENTS.md` 或 payload 目录。
9. 未受管 namespace 冲突时安装失败且不覆盖原文件。
10. marker 异常时安装失败且 `AGENTS.md` 保持不变。
11. 非法 manifest 路径在任何写入或删除前失败。
12. `--dry-run` 不产生任何写入。
13. macOS 默认 Bash 3.2 兼容，`shellcheck` 和现有回归测试全部通过。

## 10. 影响文件

| 文件 | 变更 |
|---|---|
| `adapters/codex.sh` | 新增 Codex 安装、更新、dry-run 和卸载实现 |
| `tests/codex-install.sh` | 新增 Codex 生命周期回归测试 |
| `.github/workflows/test.yml` | 将 Codex 测试纳入 CI |
| `README.md` | 更新英文安装说明和加载机制 |
| `README.zh.md` | 更新中文安装说明和加载机制 |
| `docs/codex-adapter-design.md` | 固化本设计和约束 |

`install.sh` 已按 adapter 文件名动态分发，新增 `adapters/codex.sh` 后即可工作，原则上不需要修改入口逻辑。

## 11. 禁止事项

- 禁止直接覆盖用户的 `~/.codex/AGENTS.md`。
- 禁止向 `~/.codex/rules/` 同步本仓库 Markdown rules。
- 禁止在 marker 异常时尝试猜测或修复用户文件。
- 禁止使用 `rm -rf` 清理 Codex 配置目录。
- 禁止卸载未写入 manifest 的文件。
- 禁止在 adapter 中修改 Codex model、permissions、hooks、MCP 或 skills。
- 禁止把本仓库绝对路径写入安装结果。
