# 设置窗口独立化 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将当前混合了设置与工具内容的页面拆分为独立设置窗口和独立功能页，并统一菜单“设置”入口只打开设置窗口。

**Architecture:** 复用现有 `SettingsWindowController` 作为独立设置窗口承载，将工具工作区从原 `SettingsView` 中抽离成单独视图与视图模型入口。`AppDelegate` 和状态栏菜单继续作为统一入口层，只负责打开对应窗口，不再让设置页承担工具内容展示职责。

**Tech Stack:** `Swift 6`、`SwiftUI`、`AppKit`、`XCTest`

---

### Task 1: 锁定设置窗口职责

**Files:**
- Modify: `Tests/MacTextActionsAppTests/SettingsViewModelTests.swift`
- Create: `Tests/MacTextActionsAppTests/SettingsWindowControllerTests.swift`

**Step 1: Write the failing test**

为独立设置页补充最小行为测试：
- 设置页视图模型不再持有工具内容状态
- 设置窗口控制器创建的根视图仅承载设置页面

**Step 2: Run test to verify it fails**

Run: `swift test --filter SettingsWindowControllerTests`
Expected: FAIL，提示新测试依赖的类型或行为尚不存在

**Step 3: Write minimal implementation**

引入独立设置视图模型与设置页面容器，让设置窗口明确只加载设置页面。

**Step 4: Run test to verify it passes**

Run: `swift test --filter SettingsWindowControllerTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Tests/MacTextActionsAppTests/SettingsViewModelTests.swift Tests/MacTextActionsAppTests/SettingsWindowControllerTests.swift Sources/MacTextActionsApp
git commit -m "refactor: 拆分设置窗口与工具页面职责"
```

### Task 2: 拆分功能页与入口

**Files:**
- Modify: `Sources/MacTextActionsApp/SettingsView.swift`
- Modify: `Sources/MacTextActionsApp/SettingsWindowController.swift`
- Modify: `Sources/MacTextActionsApp/AppDelegate.swift`
- Create: `Sources/MacTextActionsApp/ToolWorkspaceView.swift`

**Step 1: Write the failing test**

为工具页入口补充预期：
- 工具工作区继续提供工具切换和内容转换
- 设置窗口不再展示工具列表与工具内容

**Step 2: Run test to verify it fails**

Run: `swift test --filter SettingsViewModelTests`
Expected: FAIL，旧视图模型与视图结构不再满足新断言

**Step 3: Write minimal implementation**

抽离 `ToolWorkspaceView` 与对应视图模型，更新 `AppDelegate` 统一通过菜单打开独立设置窗口。

**Step 4: Run test to verify it passes**

Run: `swift test --filter SettingsViewModelTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/AppDelegate.swift Sources/MacTextActionsApp/SettingsView.swift Sources/MacTextActionsApp/SettingsWindowController.swift Sources/MacTextActionsApp/ToolWorkspaceView.swift
git commit -m "refactor: 分离设置页与工具工作区"
```

### Task 3: 同步文档说明

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/ui/mac-text-actions-ui.md`

**Step 1: Write the failing test**

本任务以文档一致性检查替代自动化测试，确认入口文案和页面职责一致。

**Step 2: Run check to verify current docs are stale**

Run: `rg -n "设置页当前承担|快捷键与权限卡片|工具预览|设置" README.md docs/README.md docs/ui/mac-text-actions-ui.md`
Expected: 能看到旧的混合页描述

**Step 3: Write minimal implementation**

将说明更新为“设置独立窗口 + 功能页独立承载工具内容”的结构。

**Step 4: Run check to verify docs are aligned**

Run: `rg -n "独立设置窗口|功能页|工具工作区|顶部菜单" README.md docs/README.md docs/ui/mac-text-actions-ui.md`
Expected: 三份文档都能检索到一致描述

**Step 5: Commit**

```bash
git add README.md docs/README.md docs/ui/mac-text-actions-ui.md
git commit -m "docs: 同步设置窗口独立化说明"
```
