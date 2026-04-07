# Replace Edit Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 `result panel` 中的 `替换` 动作改为进入编辑态，支持 `300ms` 防抖自动再转换，并在用户确认后才将编辑值写回当前选区。

**Architecture:** 主要改动集中在 `MacTextActionsApp` 层，新增编辑会话状态和弹框编辑态；同时在 `MacTextActionsCore` 补一个轻量上下文化转换入口，用于保留时间戳秒/毫秒精度。现有 `ContentDetector + TransformEngine` 继续作为核心转换骨架。

**Tech Stack:** `Swift 6`、`SwiftUI`、`AppKit`、`XCTest`

---

### Task 1: 为时间戳精度继承补核心失败测试

**Files:**
- Modify: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsCoreTests/TransformEngineTests.swift`
- Modify: `/Users/staff/work/qimao/person/mac-tools/Sources/MacTextActionsCore/Models.swift`
- Modify: `/Users/staff/work/qimao/person/mac-tools/Sources/MacTextActionsCore/TransformEngine.swift`

**Step 1: Write the failing test**

补充以下测试：
- 原始输入为 `10` 位时间戳时，编辑后的日期重新转换仍输出秒级时间戳
- 原始输入为 `13` 位时间戳时，编辑后的日期重新转换仍输出毫秒级时间戳

**Step 2: Run test to verify it fails**

Run: `swift test --filter TransformEngineTests`

Expected: FAIL，提示缺少上下文化转换入口或输出位数不符合预期。

**Step 3: Write minimal implementation**

新增最小上下文模型，并让 `TransformEngine` 支持编辑态转换。

**Step 4: Run test to verify it passes**

Run: `swift test --filter TransformEngineTests`

Expected: PASS

### Task 2: 为弹框编辑态补失败测试

**Files:**
- Create: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/ReplaceEditSessionTests.swift`
- Modify: `/Users/staff/work/qimao/person/mac-tools/Sources/MacTextActionsApp/LiquidGlassPopover.swift`

**Step 1: Write the failing test**

补充以下测试：
- 点击 `替换` 后不再立即请求系统写回
- 编辑态默认可编辑值为当前 `primary result`
- 编辑态保留原始选中文本只读参考

**Step 2: Run test to verify it fails**

Run: `swift test --filter ReplaceEditSessionTests`

Expected: FAIL

**Step 3: Write minimal implementation**

引入编辑会话状态模型，但先只满足状态切换和默认值。

**Step 4: Run test to verify it passes**

Run: `swift test --filter ReplaceEditSessionTests`

Expected: PASS

### Task 3: 接入 300ms 防抖自动转换

**Files:**
- Modify: `/Users/staff/work/qimao/person/mac-tools/Sources/MacTextActionsApp/LiquidGlassPopover.swift`
- Modify: `/Users/staff/work/qimao/person/mac-tools/Sources/MacTextActionsApp/PopoverController.swift`
- Modify: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/ReplaceEditSessionTests.swift`

**Step 1: Write the failing test**

补充以下测试：
- 编辑值变化后不会立刻同步写回系统
- 防抖窗口结束后会触发再转换
- 失败时保留编辑内容与错误态

**Step 2: Run test to verify it fails**

Run: `swift test --filter ReplaceEditSessionTests`

Expected: FAIL

**Step 3: Write minimal implementation**

给编辑态加入防抖调度和再转换调用。

**Step 4: Run test to verify it passes**

Run: `swift test --filter ReplaceEditSessionTests`

Expected: PASS

### Task 4: 将写回动作改为显式确认

**Files:**
- Modify: `/Users/staff/work/qimao/person/mac-tools/Sources/MacTextActionsApp/PopoverController.swift`
- Modify: `/Users/staff/work/qimao/person/mac-tools/Sources/MacTextActionsApp/AccessibilityBridge.swift`
- Modify: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/ReplaceEditSessionTests.swift`

**Step 1: Write the failing test**

补充以下测试：
- 编辑态中点击 `应用替换` 才触发 `replaceSelectedText`
- 成功写回后关闭弹框

**Step 2: Run test to verify it fails**

Run: `swift test --filter ReplaceEditSessionTests`

Expected: FAIL

**Step 3: Write minimal implementation**

将原来的 `替换` 动作拆成“进入编辑态”和“应用替换”。

**Step 4: Run test to verify it passes**

Run: `swift test --filter ReplaceEditSessionTests`

Expected: PASS

### Task 5: 跑回归验证

**Files:**
- Test: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsCoreTests/TransformEngineTests.swift`
- Test: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/ReplaceEditSessionTests.swift`
- Test: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift`
- Test: `/Users/staff/work/qimao/person/mac-tools/Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift`

**Step 1: Run core regression**

Run: `swift test --filter TransformEngineTests`

Expected: PASS

**Step 2: Run app editing regression**

Run: `swift test --filter ReplaceEditSessionTests`

Expected: PASS

**Step 3: Run presentation regression**

Run: `swift test --filter SelectionTriggerPresentationFactoryTests`

Expected: PASS

**Step 4: Run layout regression**

Run: `swift test --filter ToolContentLayoutTests`

Expected: PASS
