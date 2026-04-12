# Release Tag Trigger Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为 GitHub Actions 的发布链路新增“在 `master` 分支 push 时，根据提交信息中的 `tag:vX.Y.Z` 自动创建远程 tag 并发布 GitHub Release”的能力。

**Architecture:** 保留现有 `Release` 工作流作为唯一发布入口，在同一工作流内统一处理三种来源：`v*` tag push、`master` push 提交信息触发、手动 `workflow_dispatch`。对普通 push 先解析提交信息并决定是否创建远程 tag，再复用现有构建与发布步骤。

**Tech Stack:** GitHub Actions、Bash、Git、Swift Package

---

### Task 1: 补充发布触发设计文档

**Files:**
- Create: `docs/plans/2026-04-11-release-tag-trigger-design.md`
- Create: `docs/plans/2026-04-11-release-tag-trigger-implementation.md`

**Step 1: Write the failing test**

此任务以设计核对替代自动化测试，确认设计覆盖以下问题：

- `master` push 场景是否只在指定格式下触发
- 是否明确说明 `tag:vX.Y.Z` 的约定
- 是否避免依赖“工作流推 tag 再触发另一个工作流”

**Step 2: Run test to verify it fails**

Run: `rg -n "tag:vX.Y.Z|master push|远程 tag|同一个 Release 工作流" docs/plans`

Expected: 改动前无法在计划文档中完整检索到这些约定。

**Step 3: Write minimal implementation**

补充本次需求的设计说明与实施计划。

**Step 4: Run test to verify it passes**

Run: `rg -n "tag:vX.Y.Z|master|远程 tag|同一个 Release 工作流" docs/plans/2026-04-11-release-tag-trigger-*.md`

Expected: 两份计划文档均能检索到关键约定。

**Step 5: Commit**

```bash
git add docs/plans/2026-04-11-release-tag-trigger-design.md docs/plans/2026-04-11-release-tag-trigger-implementation.md
git commit -m "docs: 补充发布标签自动触发设计与计划"
```

### Task 2: 修改 Release 工作流以支持提交信息触发

**Files:**
- Modify: `.github/workflows/release.yml`

**Step 1: Write the failing test**

此任务以配置行为验证替代传统单元测试，覆盖：

- `push` 到 `master` 时会检查提交信息
- 命中 `tag:vX.Y.Z` 时生成 `release_tag`
- 未命中时跳过后续发布步骤
- `v*` tag push 与 `workflow_dispatch` 仍保持可用

**Step 2: Run test to verify it fails**

Run: `ruby -e 'require "yaml"; data = YAML.load_file(".github/workflows/release.yml"); on = data["on"] || data[:on]; abort("missing master push") unless on["push"]["branches"].include?("master") rescue abort("missing branch trigger")'`

Expected: 修改前失败，因为当前工作流未监听 `master` 分支 push。

**Step 3: Write minimal implementation**

在 `.github/workflows/release.yml` 中：

- 为 `push` 增加 `branches: [master]`
- 新增元数据解析步骤，区分 `workflow_dispatch`、tag push、普通 branch push
- 在普通 push 场景下从最新提交信息中解析 `tag:vX.Y.Z`
- 增加条件步骤在远程创建缺失 tag
- 为构建与发布步骤增加守卫条件，只在需要发布时执行

**Step 4: Run test to verify it passes**

Run: `ruby -e 'require "yaml"; data = YAML.load_file(".github/workflows/release.yml"); on = data["on"] || data[:on]; push = on["push"] || on[:push]; abort("missing master push") unless (push["branches"] || push[:branches]).include?("master"); abort("missing tag push") unless (push["tags"] || push[:tags]).include?("v*"); puts "ok"'`

Expected: 输出 `ok`。

**Step 5: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: 支持提交信息触发发布标签与 release"
```

### Task 3: 更新开发文档中的发布约定

**Files:**
- Modify: `docs/development/mac-text-actions-development-guidelines.md`

**Step 1: Write the failing test**

人工检查当前文档是否缺少以下说明：

- `master` push 可基于提交信息触发发布
- 固定格式 `tag:vX.Y.Z`
- 远程 tag 与 release 在同一工作流完成

**Step 2: Run test to verify it fails**

Run: `rg -n "tag:v|master|release 工作流|远程 tag" docs/development/mac-text-actions-development-guidelines.md`

Expected: 修改前缺少完整说明。

**Step 3: Write minimal implementation**

在开发文档中补充新的发布约定与使用方式。

**Step 4: Run test to verify it passes**

Run: `rg -n "tag:v|master|远程 tag|同一个工作流" docs/development/mac-text-actions-development-guidelines.md`

Expected: 能检索到新增说明。

**Step 5: Commit**

```bash
git add docs/development/mac-text-actions-development-guidelines.md
git commit -m "docs: 更新自动发布标签约定"
```

### Task 4: 完成本地校验并核对变更范围

**Files:**
- Modify: `.github/workflows/release.yml`
- Modify: `docs/development/mac-text-actions-development-guidelines.md`
- Create: `docs/plans/2026-04-11-release-tag-trigger-design.md`
- Create: `docs/plans/2026-04-11-release-tag-trigger-implementation.md`

**Step 1: Verify plan docs**

Run: `rg -n "tag:vX.Y.Z|master|远程 tag|同一个 Release 工作流" docs/plans/2026-04-11-release-tag-trigger-*.md`

Expected: 检索命中关键约定。

**Step 2: Verify workflow YAML**

Run: `ruby -e 'require "yaml"; data = YAML.load_file(".github/workflows/release.yml"); on = data["on"] || data[:on]; push = on["push"] || on[:push]; abort("missing master branch") unless (push["branches"] || push[:branches]).include?("master"); abort("missing tag trigger") unless (push["tags"] || push[:tags]).include?("v*"); puts "workflow yaml ok"'`

Expected: 输出 `workflow yaml ok`。

**Step 3: Review diff scope**

Run: `git diff -- .github/workflows/release.yml docs/development/mac-text-actions-development-guidelines.md docs/plans/2026-04-11-release-tag-trigger-design.md docs/plans/2026-04-11-release-tag-trigger-implementation.md`

Expected: 只包含本次需求相关改动。

**Step 4: Commit**

```bash
git add .github/workflows/release.yml docs/development/mac-text-actions-development-guidelines.md docs/plans/2026-04-11-release-tag-trigger-design.md docs/plans/2026-04-11-release-tag-trigger-implementation.md
git commit -m "ci: 新增提交信息触发发布能力"
```
