# Clipboard Fallback Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为全局触发主流程增加 `clipboard fallback`，并在 `result panel` 中明确展示内容来源。

**Architecture:** 变更集中在 `MacTextActionsApp` 层，保持 `MacTextActionsCore` 的检测与转换逻辑不变。`Selection Reader` 负责“优先读取选区，失败时尝试剪贴板”，`SelectionTriggerPresentationFactory` 负责把来源信息映射到展示模型，`LiquidGlassPopover` 负责把来源提示渲染到界面。

**Tech Stack:** `Swift 6`、`SwiftUI`、`AppKit`、`XCTest`

---

### Task 1: 为来源建模补上失败测试

**Files:**
- Modify: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift`
- Test: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift`

**Step 1: Write the failing test**

补充以下测试：
- `noSelection` 且回退到剪贴板时，返回成功展示，保留原始文本并标记来源为 `clipboard fallback`
- `unsupportedApplication` 且回退到剪贴板时，返回成功展示并标记来源
- 无选区且无剪贴板内容时，错误文案改为 `未检测到可处理文本`

**Step 2: Run test to verify it fails**

Run: `swift test --filter SelectionTriggerPresentationFactoryTests`

Expected: FAIL，提示缺少来源字段或错误文案不匹配。

**Step 3: Write minimal implementation**

在 app 层新增最小来源模型和展示映射，但先只满足测试。

**Step 4: Run test to verify it passes**

Run: `swift test --filter SelectionTriggerPresentationFactoryTests`

Expected: PASS

### Task 2: 为选区读取链路增加剪贴板回退

**Files:**
- Modify: `/Users/staff/work/qimao/person/mac-tools/Sources/MacTextActionsApp/AccessibilityBridge.swift`
- Modify: `/Users/staff/work/qimao/person/mac-tools/Sources/MacTextActionsApp/AppDelegate.swift`
- Test: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift`

**Step 1: Write the failing test**

让展示工厂和读取结果支持：
- 读取成功时来源为选区
- 读取失败但剪贴板有值时来源为剪贴板
- 读取失败且剪贴板为空时保留错误结果

**Step 2: Run test to verify it fails**

Run: `swift test --filter SelectionTriggerPresentationFactoryTests`

Expected: FAIL

**Step 3: Write minimal implementation**

实现：
- 新的读取结果结构，包含文本、失败原因和来源
- 剪贴板文本读取助手，过滤空白内容
- `AppDelegate` 使用新的读取结果进入展示工厂

**Step 4: Run test to verify it passes**

Run: `swift test --filter SelectionTriggerPresentationFactoryTests`

Expected: PASS

### Task 3: 在结果面板展示来源提示

**Files:**
- Modify: `/Users/staff/work/qimao/person/mac-tools/Sources/MacTextActionsApp/LiquidGlassPopover.swift`
- Modify: `/Users/staff/work/qimao/person/mac-tools/Sources/MacTextActionsApp/PopoverController.swift`
- Modify: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift`

**Step 1: Write the failing test**

新增来源文案映射测试：
- 选区来源显示 `来源：当前选中文本`
- 剪贴板来源显示 `来源：剪贴板回退`

**Step 2: Run test to verify it fails**

Run: `swift test --filter ToolContentLayoutTests`

Expected: FAIL，提示来源展示辅助模型不存在。

**Step 3: Write minimal implementation**

实现一个轻量来源展示辅助类型，并让 `LiquidGlassPopover` 在输入预览上方展示来源标签。

**Step 4: Run test to verify it passes**

Run: `swift test --filter ToolContentLayoutTests`

Expected: PASS

### Task 4: 跑回归验证

**Files:**
- Test: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift`
- Test: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift`
- Test: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsCoreTests/TransformEngineTests.swift`

**Step 1: Run focused regression suite**

Run: `swift test --filter SelectionTriggerPresentationFactoryTests`

Expected: PASS

**Step 2: Run layout regression suite**

Run: `swift test --filter ToolContentLayoutTests`

Expected: PASS

**Step 3: Run transform regression suite**

Run: `swift test --filter TransformEngineTests`

Expected: PASS
