# Accessibility Dev Build Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将开发期 app 构建流程改为固定 `Dev.app` 安装身份，并用“就地刷新”替代“反复重装整包”，降低 `Accessibility` 权限冲突频率。

**Architecture:** 保留现有 `Swift Package` 结构，只调整 `Makefile` 构建入口。先生成一个本地开发版模板，再把该模板安装到固定路径的 `Dev.app`；后续日常开发只刷新已安装 app 的可执行文件、必要资源与 bundle 元数据。长期方向仍是补齐标准 `Xcode` App target。

**Tech Stack:** `Swift Package Manager`、`make`、`plutil`、`ditto`、`open`

---

### Task 1: 收敛开发版模板产物

**Files:**
- Modify: `/Users/staff/work/qimao/person/mac-tools/Makefile`
- Test: `/Users/staff/work/qimao/person/mac-tools/Makefile`

**Step 1: 调整 build-app 行为**

将 `build-app` 改为：
- 构建 `MacTextActionsApp` release 可执行文件
- 复制 `.build/MacTextActions.app` 为本地开发版模板
- 写入固定的开发版 `Bundle Identifier` 与 `Bundle Name`
- 不再把 `.app` 复制到仓库根目录

**Step 2: Run command to verify template build**

Run: `make build-app`

Expected: PASS，并输出开发版模板路径。

**Step 3: Commit**

```bash
git add Makefile
git commit -m "build: 收敛开发版 app 模板产物"
```

### Task 2: 新增固定路径安装与刷新命令

**Files:**
- Modify: `/Users/staff/work/qimao/person/mac-tools/Makefile`
- Test: `/Users/staff/work/qimao/person/mac-tools/Makefile`

**Step 1: 新增安装命令**

补充：
- `install-dev-app`
- `refresh-dev-app`
- `run-dev-app`
- `dev-app`

命令职责：
- `install-dev-app`：首次把模板安装到 `~/Applications/MacTextActions Dev.app`
- `refresh-dev-app`：就地刷新已安装 app
- `run-dev-app`：打开固定开发版 app
- `dev-app`：日常入口，自动刷新并启动

**Step 2: Run command to verify install flow**

Run: `make install-dev-app`

Expected: PASS，并在 `~/Applications` 生成固定开发版 app。

**Step 3: Run command to verify refresh flow**

Run: `make refresh-dev-app`

Expected: PASS，并输出已刷新固定开发版 app。

**Step 4: Commit**

```bash
git add Makefile
git commit -m "build: 新增开发版固定安装与刷新命令"
```

### Task 3: 回归验证并固化使用方式

**Files:**
- Modify: `/Users/staff/work/qimao/person/mac-tools/docs/plans/2026-04-07-accessibility-dev-build-design.md`
- Modify: `/Users/staff/work/qimao/person/mac-tools/docs/plans/2026-04-07-accessibility-dev-build-implementation.md`
- Test: `/Users/staff/work/qimao/person/mac-tools/Makefile`

**Step 1: Run local build regression**

Run: `make build-app`

Expected: PASS

**Step 2: Run day-to-day entry regression**

Run: `make dev-app`

Expected: PASS，并成功打开固定开发版 app。

**Step 3: 记录边界**

在设计与计划文档中明确说明：
- 当前方案是过渡方案
- 若权限仍不稳定，应升级到标准 `Xcode` App target

**Step 4: Commit**

```bash
git add docs/plans/2026-04-07-accessibility-dev-build-design.md docs/plans/2026-04-07-accessibility-dev-build-implementation.md Makefile
git commit -m "docs: 补充开发版权限稳定化方案"
```
