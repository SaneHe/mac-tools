# Option 型 Secondary Action Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为 `result panel` 与独立工具窗口统一实现 option 型 `secondary action` 规则，并将该规则写入项目文档。

**Architecture:** 在 `MacTextActionsCore` 中扩展 `TransformContext` 与 `TransformResult`，为 MD5 大小写和日期转时间戳秒/毫秒提供统一的 option 元数据；UI 层只消费统一模型，不再各自维护 `Toggle` 或硬编码切换逻辑。

**Tech Stack:** Swift 6、SwiftUI、AppKit、XCTest、MacTextActionsCore

---

### Task 1: 为核心模型补充 option action 表达

**Files:**
- Modify: `Sources/MacTextActionsCore/Models.swift`
- Test: `Tests/MacTextActionsCoreTests/TransformEngineTests.swift`
- Test: `Tests/MacTextActionsCoreTests/SecondaryActionPerformerTests.swift`

**Step 1: Write the failing test**

在 `Tests/MacTextActionsCoreTests/TransformEngineTests.swift` 新增测试，覆盖：

- `MD5` 指定模式默认输出小写，并暴露 `转大写` option
- 切换 option 后输出大写，并暴露 `转小写`
- `日期转时间戳` 默认输出秒级，并暴露 `转毫秒`
- 切换 option 后输出毫秒级，并暴露 `转秒级`

**Step 2: Run test to verify it fails**

Run: `swift test --filter TransformEngineTests`

Expected: 新增断言失败，提示缺少 option 元数据或结果未按 option 切换。

**Step 3: Write minimal implementation**

在 `Sources/MacTextActionsCore/Models.swift` 中：

- 为 `TransformContext` 增加 `md5LetterCase`、`timestampOutputPrecision` 等 option 状态
- 为 `TransformResult` 增加可选的 option action 描述结构

在 `Sources/MacTextActionsCore/TransformEngine.swift` 与 `Sources/MacTextActionsCore/SecondaryActionPerformer.swift` 中：

- 支持按 context 生成大小写不同的 MD5
- 支持按 context 生成秒级或毫秒级时间戳

**Step 4: Run test to verify it passes**

Run: `swift test --filter TransformEngineTests`

Expected: 新增测试通过。

**Step 5: Commit**

```bash
git add Sources/MacTextActionsCore/Models.swift Sources/MacTextActionsCore/TransformEngine.swift Sources/MacTextActionsCore/SecondaryActionPerformer.swift Tests/MacTextActionsCoreTests/TransformEngineTests.swift Tests/MacTextActionsCoreTests/SecondaryActionPerformerTests.swift
git commit -m "feat(core): 统一 option 型二次操作模型"
```

### Task 2: 让快捷键 result panel 使用统一 option action

**Files:**
- Modify: `Sources/MacTextActionsApp/AppDelegate.swift`
- Modify: `Sources/MacTextActionsApp/LiquidGlassPopover.swift`
- Modify: `Sources/MacTextActionsApp/PopoverController.swift`
- Test: `Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift`
- Test: `Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift`

**Step 1: Write the failing test**

新增测试，覆盖：

- 指定模式 `MD5` 默认结果带 `转大写` option
- 指定模式 `日期转时间戳` 默认结果带 `转毫秒` option
- `LiquidGlassPopover` 相关状态能根据结果暴露 option 按钮文案

**Step 2: Run test to verify it fails**

Run: `swift test --filter SelectionTriggerPresentationFactoryTests --filter ToolContentLayoutTests`

Expected: 新增测试失败，提示 presentation 或布局状态缺少 option 信息。

**Step 3: Write minimal implementation**

- 在 `Sources/MacTextActionsApp/AppDelegate.swift` 中让显式模式执行传入正确 context
- 在 `Sources/MacTextActionsApp/LiquidGlassPopover.swift` 中统一渲染底部 `option` 按钮
- 点击按钮后基于同一输入与更新后的 context 重新计算结果

**Step 4: Run test to verify it passes**

Run: `swift test --filter SelectionTriggerPresentationFactoryTests --filter ToolContentLayoutTests`

Expected: 新增测试通过。

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/AppDelegate.swift Sources/MacTextActionsApp/LiquidGlassPopover.swift Sources/MacTextActionsApp/PopoverController.swift Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift
git commit -m "feat(app): 为结果面板接入 option 型二次操作"
```

### Task 3: 让独立工具窗口移除 Toggle 并统一到底部 action bar

**Files:**
- Modify: `Sources/MacTextActionsApp/ToolContentView.swift`
- Modify: `Sources/MacTextActionsApp/SidebarView.swift`
- Test: `Tests/MacTextActionsAppTests/ToolWorkspaceViewModelTests.swift`
- Test: `Tests/MacTextActionsAppTests/PanelContentFactoryTests.swift`

**Step 1: Write the failing test**

新增测试，覆盖：

- `ToolContentViewModel` 中 `MD5` 默认小写，切换 option 后输出大写
- `ToolContentViewModel` 中日期输入默认输出秒级时间戳，切换 option 后输出毫秒级
- 工具描述文案不再暗示输入区存在 `Toggle`

**Step 2: Run test to verify it fails**

Run: `swift test --filter ToolWorkspaceViewModelTests --filter PanelContentFactoryTests`

Expected: 新增测试失败，提示 view model 缺少统一 option 切换能力。

**Step 3: Write minimal implementation**

- 删除 `Sources/MacTextActionsApp/ToolContentView.swift` 中 `Toggle` 相关状态与 UI
- 为 `ToolContentViewModel` 增加统一 option 状态、按钮文案和切换方法
- 在底部 action bar 中追加 option 按钮并驱动刷新

**Step 4: Run test to verify it passes**

Run: `swift test --filter ToolWorkspaceViewModelTests --filter PanelContentFactoryTests`

Expected: 新增测试通过。

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/ToolContentView.swift Sources/MacTextActionsApp/SidebarView.swift Tests/MacTextActionsAppTests/ToolWorkspaceViewModelTests.swift Tests/MacTextActionsAppTests/PanelContentFactoryTests.swift
git commit -m "feat(workspace): 统一工具页 option 二次操作交互"
```

### Task 4: 更新产品与 UI 文档

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/product.md`
- Modify: `docs/ui/mac-text-actions-ui.md`
- Modify: `docs/implementation.md`

**Step 1: Write the failing test**

此任务以文档一致性检查替代自动化测试，人工核对以下要求：

- `option` 型二次操作被定义为统一交互规则
- `MD5` 与 `日期转时间戳` 的默认值和切换逻辑已写明
- 未来新增带 option 的功能必须复用该规则

**Step 2: Run test to verify it fails**

Run: `rg -n "option|转大写|转小写|转毫秒|转秒级|二次操作" README.md docs`

Expected: 改动前匹配不足，无法完整表达规则。

**Step 3: Write minimal implementation**

把统一规则写入仓库文档，避免后续实现漂移。

**Step 4: Run test to verify it passes**

Run: `rg -n "option|转大写|转小写|转毫秒|转秒级|二次操作" README.md docs`

Expected: 关键文档均能检索到统一规则。

**Step 5: Commit**

```bash
git add README.md docs/README.md docs/product.md docs/ui/mac-text-actions-ui.md docs/implementation.md
git commit -m "docs: 补充 option 型二次操作统一规则"
```

### Task 5: 完整验证并整理交付说明

**Files:**
- Modify: `docs/plans/2026-04-11-option-secondary-actions-design.md`
- Modify: `docs/plans/2026-04-11-option-secondary-actions-implementation.md`

**Step 1: Run focused test suites**

Run: `swift test --filter TransformEngineTests`

Run: `swift test --filter SecondaryActionPerformerTests`

Run: `swift test --filter SelectionTriggerPresentationFactoryTests`

Run: `swift test --filter ToolContentLayoutTests`

Run: `swift test --filter ToolWorkspaceViewModelTests`

Run: `swift test --filter PanelContentFactoryTests`

**Step 2: Run full verification**

Run: `swift test`

Expected: 全部测试通过。

**Step 3: Review changed files**

Run: `git diff --stat`

Expected: 仅包含本次需求相关改动与用户已有的并行改动。

**Step 4: Commit**

```bash
git add docs/plans/2026-04-11-option-secondary-actions-design.md docs/plans/2026-04-11-option-secondary-actions-implementation.md
git commit -m "docs: 补充 option 二次操作设计与实施计划"
```

Plan complete and saved to `docs/plans/2026-04-11-option-secondary-actions-implementation.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?
