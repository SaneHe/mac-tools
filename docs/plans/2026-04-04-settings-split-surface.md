# Settings Split Surface Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为设置窗口和工具工作区补齐类似 Codex 的左右分块视觉，让右侧内容区成为独立的圆角工作区卡片。

**Architecture:** 保持现有左右栏结构不变，只在容器层增加共享视觉样式。通过在 `SettingsView` 中集中定义分块卡片的圆角、边框、阴影和内边距，并在 `ToolWorkspaceView` 复用，避免把样式散落到具体内容卡片里。

**Tech Stack:** `Swift 6`、`SwiftUI`、`AppKit`、`XCTest`

---

### Task 1: 锁定分块容器样式

**Files:**
- Modify: `Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift`
- Modify: `Sources/MacTextActionsApp/SettingsView.swift`
- Modify: `Sources/MacTextActionsApp/ToolWorkspaceView.swift`

**Step 1: Write the failing test**

为共享分块样式增加断言：
- 右侧工作区容器存在独立圆角
- 容器阴影和描边使用固定常量
- 左右区域之间保留独立外边距，避免重新贴回整窗背景

**Step 2: Run test to verify it fails**

Run: `swift test --filter ToolContentLayoutTests`
Expected: FAIL，提示新的样式常量或状态结构不存在

**Step 3: Write minimal implementation**

在 `SettingsView.swift` 增加共享分块样式常量与辅助容器，在 `ToolWorkspaceView.swift` 应用右侧圆角卡片容器。

**Step 4: Run test to verify it passes**

Run: `swift test --filter ToolContentLayoutTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift Sources/MacTextActionsApp/SettingsView.swift Sources/MacTextActionsApp/ToolWorkspaceView.swift
git commit -m "feat: 增强工作区左右分块视觉"
```
