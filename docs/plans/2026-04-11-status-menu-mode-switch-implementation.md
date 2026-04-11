# Status Menu Mode Switch Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为状态栏菜单增加单层模式列表、菜单内 `Command + 数字` 切换、默认模式持有与 `global shortcut` 按当前模式直接执行的完整链路。

**Architecture:** 在 app 层新增一个轻量的“默认执行模式”状态对象，由 `StatusBarController` 负责菜单展示与切换，由 `AppDelegate` 在触发 `global shortcut` 时读取当前模式并构造对应的 `SelectionTriggerPresentation`。核心转换逻辑继续优先复用 `MacTextActionsCore` 的 `ContentDetector`、`TransformEngine` 与 `SecondaryActionPerformer`，只为“显式指定模式”补一层显式执行入口，避免把菜单逻辑塞进视图或 popover 内。

**Tech Stack:** `Swift 6`, `SwiftUI`, `AppKit`, `XCTest`, `MacTextActionsCore`

---

### Task 1: 定义默认执行模式模型

**Files:**
- Create: `Sources/MacTextActionsApp/ExecutionMode.swift`
- Test: `Tests/MacTextActionsAppTests/StatusBarControllerTests.swift`

**Step 1: Write the failing test**

在 `Tests/MacTextActionsAppTests/StatusBarControllerTests.swift` 新增测试，断言状态栏菜单会包含：
- `自动识别`
- `创建提醒事项`
- `JSON 格式化`
- `JSON Compress`
- `时间戳转本地时间`
- `日期转时间戳`
- `MD5`

并断言默认勾选项是 `自动识别`。

**Step 2: Run test to verify it fails**

Run: `swift test --filter StatusBarControllerTests/testStatusBarMenuContainsAllExecutionModes`
Expected: FAIL，因为当前状态栏菜单还没有这些模式项。

**Step 3: Write minimal implementation**

创建 `Sources/MacTextActionsApp/ExecutionMode.swift`，定义：
- `ExecutionMode` 枚举
- 每个模式的 `menuTitle`
- 每个模式的 `keyEquivalent`
- 每个模式的 `keyEquivalentModifierMask`
- `automatic` 作为默认值

**Step 4: Run test to verify it passes**

Run: `swift test --filter StatusBarControllerTests/testStatusBarMenuContainsAllExecutionModes`
Expected: PASS

**Step 5: Commit**

```bash
git add Tests/MacTextActionsAppTests/StatusBarControllerTests.swift Sources/MacTextActionsApp/ExecutionMode.swift
git commit -m "feat: add execution mode definitions"
```

### Task 2: 让状态栏菜单支持模式切换与勾选态

**Files:**
- Modify: `Sources/MacTextActionsApp/StatusBarController.swift`
- Test: `Tests/MacTextActionsAppTests/StatusBarControllerTests.swift`

**Step 1: Write the failing test**

新增测试覆盖：
- 默认模式项带勾选态
- 选中某个模式后，只有该项为 `.on`
- 模式项快捷键分别显示为 `⌘1` 到 `⌘7`
- “设置...” 和 “退出” 仍存在

**Step 2: Run test to verify it fails**

Run: `swift test --filter StatusBarControllerTests`
Expected: FAIL，因为 `StatusBarController` 目前只有“打开工具 / 设置 / 退出”。

**Step 3: Write minimal implementation**

在 `StatusBarController` 中：
- 持有当前 `ExecutionMode`
- 暴露 `onExecutionModeChanged`
- 使用模式枚举批量构建单层菜单项
- 为模式菜单项绑定统一 action
- 切换模式后刷新勾选态
- 保留 `设置...` 与 `退出`

**Step 4: Run test to verify it passes**

Run: `swift test --filter StatusBarControllerTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/StatusBarController.swift Tests/MacTextActionsAppTests/StatusBarControllerTests.swift
git commit -m "feat: add status bar execution mode menu"
```

### Task 3: 将快捷键说明同步到设置文案

**Files:**
- Modify: `Sources/MacTextActionsApp/ShortcutSettings.swift`
- Modify: `Tests/MacTextActionsAppTests/SettingsViewModelTests.swift`

**Step 1: Write the failing test**

更新 `AppSettingsViewModelTests`，断言工具切换摘要文案改为：
- `⌘1 自动识别 / ⌘2 创建提醒事项 / ⌘3 JSON 格式化 / ⌘4 JSON Compress / ⌘5 时间戳转本地时间 / ⌘6 日期转时间戳 / ⌘7 MD5`

并保留“仅用于菜单切换”的语义表达。

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppSettingsViewModelTests/testShortcutSummaryUsesMenuCommandShortcuts`
Expected: FAIL，因为当前仍显示 `Ctrl+1 / Ctrl+2 / Ctrl+3 / Ctrl+4`。

**Step 3: Write minimal implementation**

更新 `AppShortcutConfiguration.toolSwitchShortcutValue`，使设置页说明与菜单内命令快捷键一致。

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppSettingsViewModelTests/testShortcutSummaryUsesMenuCommandShortcuts`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/ShortcutSettings.swift Tests/MacTextActionsAppTests/SettingsViewModelTests.swift
git commit -m "docs: update shortcut summary for menu mode switching"
```

### Task 4: 为显式模式执行补 presentation 构建入口

**Files:**
- Modify: `Sources/MacTextActionsApp/AppDelegate.swift`
- Modify: `Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift`
- Modify: `Sources/MacTextActionsCore/Models.swift`

**Step 1: Write the failing test**

新增测试覆盖：
- `automatic` 模式仍沿用自动识别
- `jsonFormat` 模式会直接格式化输入
- `jsonCompress` 模式会直接压缩输入
- `timestampToLocalDateTime` 模式会直接解析时间戳
- `dateToTimestamp` 模式会直接解析日期字符串
- `md5` 模式会直接生成 `MD5`

为了让标题语义可用，还需要为 `TransformResult` 增加一个轻量标识字段，例如 `presentationTitle` 或 `executionSummary`，测试中应断言自动模式和指定模式的展示文案不同。

**Step 2: Run test to verify it fails**

Run: `swift test --filter SelectionTriggerPresentationFactoryTests`
Expected: FAIL，因为当前 presentation factory 只有自动识别入口。

**Step 3: Write minimal implementation**

在 `AppDelegate.swift` 中：
- 扩展 `SelectionTriggerPresentationFactory`
- 新增 `makePresentation(from:mode:)`
- 为显式模式直接走对应转换
- 自动模式仍复用现有检测顺序

在 `Models.swift` 中：
- 为 `TransformResult` 增加不侵入现有逻辑的展示元数据字段，供 popover 顶部使用

**Step 4: Run test to verify it passes**

Run: `swift test --filter SelectionTriggerPresentationFactoryTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/AppDelegate.swift Sources/MacTextActionsCore/Models.swift Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift
git commit -m "feat: add explicit execution mode presentations"
```

### Task 5: 接通 `global shortcut` 与当前默认模式

**Files:**
- Modify: `Sources/MacTextActionsApp/AppDelegate.swift`
- Test: `Tests/MacTextActionsAppTests/StatusBarControllerTests.swift`

**Step 1: Write the failing test**

新增一个小型 app 层测试，验证：
- `StatusBarController` 切换模式后，`AppDelegate` 使用该模式处理 `global shortcut`
- 未切换时仍使用 `automatic`

如果直接测试 `AppDelegate` 过重，则先抽一个纯函数或小型协调器，并对该协调器写测试。

**Step 2: Run test to verify it fails**

Run: `swift test --filter MacTextActionsAppTests`
Expected: FAIL，因为当前 `handleSpaceTrigger()` 不读取模式状态。

**Step 3: Write minimal implementation**

在 `AppDelegate` 中：
- 持有当前 `ExecutionMode`
- 订阅 `StatusBarController.onExecutionModeChanged`
- 在 `handleSpaceTrigger()` 调用新的 `makePresentation(from:mode:)`

**Step 4: Run test to verify it passes**

Run: `swift test --filter MacTextActionsAppTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/AppDelegate.swift Tests/MacTextActionsAppTests
git commit -m "feat: route global shortcut through selected execution mode"
```

### Task 6: 更新 `result panel` 顶部标题语义

**Files:**
- Modify: `Sources/MacTextActionsApp/LiquidGlassPopover.swift`
- Test: `Tests/MacTextActionsAppTests/PanelContentFactoryTests.swift`

**Step 1: Write the failing test**

新增测试，断言：
- 自动模式结果显示 `自动识别 · ...`
- 指定模式结果显示 `指定模式 · ...`
- 失败态优先显示错误语义，不丢失模式来源

**Step 2: Run test to verify it fails**

Run: `swift test --filter PanelContentFactoryTests`
Expected: FAIL，因为当前标题还是根据 `displayMode` 猜测。

**Step 3: Write minimal implementation**

在 `LiquidGlassPopover` 中改为优先读取 `TransformResult` 的展示元数据，不再从 `primaryOutput` 内容反推标题。

**Step 4: Run test to verify it passes**

Run: `swift test --filter PanelContentFactoryTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/LiquidGlassPopover.swift Tests/MacTextActionsAppTests/PanelContentFactoryTests.swift
git commit -m "feat: show execution mode titles in result panel"
```

### Task 7: 同步文档入口

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/design/mac-text-actions-design.md`
- Modify: `docs/interaction/mac-text-actions-interaction-flow.md`
- Modify: `docs/ui/mac-text-actions-ui.md`

**Step 1: Write the doc diff**

更新文档使其与实现一致：
- 状态栏菜单不再只是设置与退出入口
- 增加单层模式列表与菜单内 `⌘数字` 切换
- `global shortcut` 按当前默认模式执行
- `自动识别` 与“指定模式执行”共存

**Step 2: Verify changed docs are internally consistent**

Run: `rg -n "Ctrl\\+1|Ctrl\\+2|Ctrl\\+3|Ctrl\\+4|菜单栏仅承担辅助职责|打开工具" README.md docs`
Expected: only intentionally retained matches remain

**Step 3: Save minimal aligned updates**

只改与本次功能直接相关的行为描述，不顺手扩展其他范围。

**Step 4: Re-run consistency check**

Run: `rg -n "⌘0|⌘1|自动识别|指定模式" README.md docs`
Expected: updated docs show the new behavior consistently

**Step 5: Commit**

```bash
git add README.md docs/README.md docs/design/mac-text-actions-design.md docs/interaction/mac-text-actions-interaction-flow.md docs/ui/mac-text-actions-ui.md
git commit -m "docs: align menu mode switching behavior"
```

### Task 8: 完整验证

**Files:**
- Modify if needed: any failing file from previous tasks

**Step 1: Run focused tests**

Run:
- `swift test --filter StatusBarControllerTests`
- `swift test --filter AppSettingsViewModelTests`
- `swift test --filter SelectionTriggerPresentationFactoryTests`

Expected: PASS

**Step 2: Run broader app/core regression tests**

Run:
- `swift test --filter MacTextActionsCoreTests`
- `swift test --filter MacTextActionsAppTests`

Expected: PASS

**Step 3: Fix any regressions minimally**

如果失败，先修回归，再重跑对应测试，直到输出与本计划一致。

**Step 4: Confirm docs and code are staged intentionally**

Run: `git status --short`
Expected: 只包含本次相关改动和用户原有未跟踪文件

**Step 5: Final commit**

```bash
git add Sources Tests README.md docs
git commit -m "feat: add status menu execution mode switching"
```
