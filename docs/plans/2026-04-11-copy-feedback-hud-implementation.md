# Copy Feedback HUD Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为所有复制入口提供统一的底部居中 `已复制` HUD，覆盖 `result panel`、独立工具窗口和双击复制场景，并保持 `macOS 13` 兼容。

**Architecture:** 通过新增 `CopyFeedbackHUD` 展示组件与 `CopyFeedbackHost` 状态宿主，把“复制反馈”从现有各复制入口中抽离出来，统一收口到 `SwiftUI` 容器层。`AppKit` 文本视图只负责完成复制与上抛成功事件，`result panel` 则在展示 HUD 后短暂延迟关闭。

**Tech Stack:** `Swift 6`、`SwiftUI`、`AppKit bridge`、`XCTest`

---

### Task 1: 建立 HUD 状态模型与基础视图

**Files:**
- Create: `Sources/MacTextActionsApp/CopyFeedbackHUD.swift`
- Test: `Tests/MacTextActionsAppTests/CopyFeedbackHUDTests.swift`

**Step 1: Write the failing test**

在 `Tests/MacTextActionsAppTests/CopyFeedbackHUDTests.swift` 中新增状态层测试，覆盖：

- `CopyFeedbackState` 初始为隐藏
- 调用触发方法后，状态变为可见
- 重复触发时，重播标识或序号递增，用于驱动动画重播

示例断言方向：

```swift
func testCopyFeedbackStateBecomesVisibleAfterTrigger() {
    let state = CopyFeedbackState()

    state.show()

    XCTAssertTrue(state.isVisible)
    XCTAssertEqual(state.replayToken, 1)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter CopyFeedbackHUDTests`
Expected: FAIL，提示 `CopyFeedbackState` 或对应测试目标尚不存在

**Step 3: Write minimal implementation**

在 `Sources/MacTextActionsApp/CopyFeedbackHUD.swift` 中新增：

- `CopyFeedbackState`
- `CopyFeedbackHUDMetrics`
- `CopyFeedbackHUD` 基础视图

最小实现要求：

- 状态对象支持 `show()` 与 `hide()`
- 维护 `isVisible` 与 `replayToken`
- HUD 使用固定文案 `已复制` 与 `checkmark`
- 先以 `SwiftUI` 基础材质、描边与阴影搭出最小可用视觉

**Step 4: Run test to verify it passes**

Run: `swift test --filter CopyFeedbackHUDTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/CopyFeedbackHUD.swift Tests/MacTextActionsAppTests/CopyFeedbackHUDTests.swift
git commit -m "feat(ui): 添加复制反馈 HUD 基础组件"
```

### Task 2: 为工具页接入统一复制反馈

**Files:**
- Modify: `Sources/MacTextActionsApp/ToolWorkspaceView.swift`
- Modify: `Sources/MacTextActionsApp/ToolContentView.swift`
- Modify: `Tests/MacTextActionsAppTests/SettingsViewModelTests.swift`
- Test: `Tests/MacTextActionsAppTests/CopyFeedbackHUDTests.swift`

**Step 1: Write the failing test**

新增或补充测试，验证：

- 工具页复制当前输出成功时会触发 HUD 展示
- 没有输出内容时，不显示 HUD

建议优先在状态或视图模型层落测试，而不是依赖完整 UI 运行。

**Step 2: Run test to verify it fails**

Run: `swift test --filter SettingsViewModelTests`
Expected: FAIL，提示工具页尚未暴露 HUD 触发状态

**Step 3: Write minimal implementation**

实现要点：

- 在 `ToolWorkspaceView` 挂载 `CopyFeedbackHUD` overlay
- 为工作区持有统一的反馈状态对象
- 将 `ToolContentView` 的复制按钮与动作栏复制动作改为在复制成功后触发反馈
- 保持无输出时 `copyOutput()` 返回 `false` 的现有约束

**Step 4: Run test to verify it passes**

Run: `swift test --filter SettingsViewModelTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/ToolWorkspaceView.swift Sources/MacTextActionsApp/ToolContentView.swift Tests/MacTextActionsAppTests/SettingsViewModelTests.swift Tests/MacTextActionsAppTests/CopyFeedbackHUDTests.swift
git commit -m "feat(ui): 为工具页复制动作接入统一反馈"
```

### Task 3: 为 result panel 接入 HUD 并调整关闭时序

**Files:**
- Modify: `Sources/MacTextActionsApp/LiquidGlassPopover.swift`
- Modify: `Sources/MacTextActionsApp/PopoverController.swift`
- Modify: `Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift`
- Test: `Tests/MacTextActionsAppTests/PopoverControllerTests.swift`

**Step 1: Write the failing test**

新增测试，覆盖：

- `result panel` 复制成功后会触发 HUD 展示
- `PopoverController` 不再在复制瞬间立即关闭，而是允许一个短暂延迟

如果当前 `PopoverControllerTests` 已有 close 行为覆盖，优先在原文件中补充断言。

**Step 2: Run test to verify it fails**

Run: `swift test --filter PopoverControllerTests`
Expected: FAIL，提示复制后仍是立即关闭或缺少 HUD 状态驱动

**Step 3: Write minimal implementation**

实现要点：

- 在 `LiquidGlassPopover` 根层挂载 `CopyFeedbackHUD`
- 复制按钮点击后先写剪贴板，再显示 HUD
- 调整 `PopoverController` 的 `onCopy` 闭包行为，使 `result panel` 在约 `0.65s` 后关闭
- 确保延迟关闭期间不会破坏外部点击关闭和现有 `onDisappear` 清理逻辑

**Step 4: Run test to verify it passes**

Run: `swift test --filter PopoverControllerTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/LiquidGlassPopover.swift Sources/MacTextActionsApp/PopoverController.swift Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift Tests/MacTextActionsAppTests/PopoverControllerTests.swift
git commit -m "feat(ui): 为结果面板复制反馈增加 HUD 动画"
```

### Task 4: 移除旧 AppKit toast，并让双击复制走统一反馈

**Files:**
- Modify: `Sources/MacTextActionsApp/StyledTextEditor.swift`
- Modify: `Tests/MacTextActionsAppTests/StyledTextEditorTests.swift`
- Modify: `Sources/MacTextActionsApp/LiquidGlassPopover.swift`
- Modify: `Sources/MacTextActionsApp/ToolContentView.swift`

**Step 1: Write the failing test**

新增测试，覆盖：

- 双击复制成功后，不再依赖旧 `CopyToastPresenter`
- `CopyableTextView` 与 `CenteredTextView` 能通过回调把复制成功事件传递给外层

示例断言方向：

```swift
func testCopyableTextViewReportsCopySuccessToContainer() {
    let expectation = expectation(description: "双击复制会回传成功事件")
    let textView = CopyableTextView()
    textView.onCopySucceeded = {
        expectation.fulfill()
    }

    // 构造选区并触发复制逻辑
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter StyledTextEditorTests`
Expected: FAIL，提示缺少回调能力或仍依赖旧 presenter

**Step 3: Write minimal implementation**

实现要点：

- 删除或弃用 `CopyToastStyle` / `CopyToastPresenter`
- 为 `CopyableTextView` 与 `CenteredTextView` 增加复制成功回调
- `SelectableCopyableText` 暴露回调入口给 `LiquidGlassPopover`
- 工具页与 `result panel` 统一通过宿主 HUD 处理反馈展示

**Step 4: Run test to verify it passes**

Run: `swift test --filter StyledTextEditorTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/StyledTextEditor.swift Sources/MacTextActionsApp/LiquidGlassPopover.swift Sources/MacTextActionsApp/ToolContentView.swift Tests/MacTextActionsAppTests/StyledTextEditorTests.swift
git commit -m "refactor(ui): 统一双击复制反馈路径"
```

### Task 5: 完成动效打磨与回归验证

**Files:**
- Modify: `Sources/MacTextActionsApp/CopyFeedbackHUD.swift`
- Modify: `Tests/MacTextActionsAppTests/CopyFeedbackHUDTests.swift`
- Modify: `Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift`

**Step 1: Write the failing test**

补充测试，覆盖：

- HUD 重复触发时只保留一个实例
- 不同底部 inset 下位置计算稳定
- `result panel` 与工具页都能读取一致的时长与布局常量

**Step 2: Run test to verify it fails**

Run: `swift test --filter CopyFeedbackHUDTests`
Expected: FAIL，提示缺少重复触发或布局约束覆盖

**Step 3: Write minimal implementation**

实现要点：

- 收敛 HUD 动效参数、停留时长与 inset 常量
- 根据测试结果微调材质、描边、阴影与动画节奏
- 保证不遮挡主要结果区与底部动作栏

**Step 4: Run test to verify it passes**

Run: `swift test --filter CopyFeedbackHUDTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/CopyFeedbackHUD.swift Tests/MacTextActionsAppTests/CopyFeedbackHUDTests.swift Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift
git commit -m "test(ui): 完善复制反馈 HUD 回归覆盖"
```

### Task 6: 全量验证与文档对齐

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/ui/mac-text-actions-ui.md`

**Step 1: Write the failing test**

这一任务不新增单元测试，改为先记录需要人工验证的交互检查项：

- 工具页复制按钮反馈
- `result panel` 复制按钮反馈
- 双击复制反馈
- 重复复制时 HUD 不叠层
- `result panel` 复制后的关闭节奏自然

**Step 2: Run test to verify it fails**

Run: `swift test`
Expected: 如果仓库内存在并行改动导致失败，先记录失败范围；若通过，则继续人工验证

**Step 3: Write minimal implementation**

同步更新文档，补充：

- “复制成功后显示底部居中的 `已复制` HUD”
- “所有复制入口统一反馈”
- “`result panel` 复制后短暂确认再关闭”

**Step 4: Run test to verify it passes**

Run: `swift test`
Expected: PASS；若受并行改动影响，至少保证本次新增相关测试通过，并记录剩余风险

**Step 5: Commit**

```bash
git add README.md docs/README.md docs/ui/mac-text-actions-ui.md
git commit -m "docs: 补充复制反馈 HUD 交互说明"
```
