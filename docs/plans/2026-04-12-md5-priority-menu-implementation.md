# MD5 优先级与顶部菜单收缩 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 收缩顶部默认模式列表为 `自动识别 / MD5 / JSON Compress`，并让自动识别命中的普通文本在结果面板中优先推荐 `MD5`。

**Architecture:** 以 `ExecutionMode` 为单一菜单模式来源，先通过测试锁定菜单项和快捷键收缩，再扩展 `TransformResult` 元数据与 `LiquidGlassPopover` 渲染逻辑，让 `plain text` 的 `actionsOnly` 状态可以展示推荐提示并优先执行 `MD5`。同时同步更新仓库中的权威产品文档与入口说明，保持产品规则、UI 文案和实现一致。

**Tech Stack:** Swift 6、SwiftUI、AppKit、XCTest、Markdown 文档

---

### Task 1: 锁定新的顶部菜单模式与快捷键

**Files:**
- Modify: `/Users/sane/person/work-for-person/mac-tools/Tests/MacTextActionsAppTests/StatusBarControllerTests.swift`
- Modify: `/Users/sane/person/work-for-person/mac-tools/Tests/MacTextActionsAppTests/ExecutionModeShortcutTests.swift`
- Modify: `/Users/sane/person/work-for-person/mac-tools/Tests/MacTextActionsAppTests/SettingsViewModelTests.swift`
- Modify: `/Users/sane/person/work-for-person/mac-tools/Sources/MacTextActionsApp/ExecutionMode.swift`

**Step 1: 写失败测试**

- 让菜单顺序只断言前三项：`自动识别`、`MD5`、`JSON Compress`
- 让快捷键摘要只断言 `⌘1` 到 `⌘3`
- 让菜单 keyEquivalent 只覆盖这三项

**Step 2: 运行相关测试并确认失败**

Run: `swift test --filter StatusBarControllerTests`
Run: `swift test --filter ExecutionModeShortcutTests`
Run: `swift test --filter AppSettingsViewModelTests`

Expected:

- 旧的 6 项菜单顺序断言失败
- 旧的快捷键摘要断言失败

**Step 3: 写最小实现**

- 在 `ExecutionMode` 中移除 `jsonFormat`、`timestampToLocalDateTime`、`dateToTimestamp`
- 更新 `menuTitle`、`shortcutIndex` 和 `shortcutSummaryText`

**Step 4: 重跑测试并确认通过**

Run: `swift test --filter StatusBarControllerTests`
Run: `swift test --filter ExecutionModeShortcutTests`
Run: `swift test --filter AppSettingsViewModelTests`

Expected: 全部 PASS

### Task 2: 锁定普通文本下的 MD5 推荐交互

**Files:**
- Modify: `/Users/sane/person/work-for-person/mac-tools/Tests/MacTextActionsCoreTests/TransformEngineTests.swift`
- Modify: `/Users/sane/person/work-for-person/mac-tools/Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift`
- Modify: `/Users/sane/person/work-for-person/mac-tools/Sources/MacTextActionsCore/Models.swift`
- Modify: `/Users/sane/person/work-for-person/mac-tools/Sources/MacTextActionsCore/TransformEngine.swift`
- Modify: `/Users/sane/person/work-for-person/mac-tools/Sources/MacTextActionsApp/AppDelegate.swift`

**Step 1: 写失败测试**

- 为 `plain text` 的 `TransformResult` 增加推荐提示文案断言
- 断言 `secondaryActions` 里 `generateMD5` 位于第一位
- 在 `SelectionTriggerPresentationFactoryTests` 中断言普通文本标题仍是 `自动识别 · 文本`

**Step 2: 运行相关测试并确认失败**

Run: `swift test --filter TransformEngineTests`
Run: `swift test --filter SelectionTriggerPresentationFactoryTests`

Expected:

- 缺少推荐提示字段导致断言失败
- 动作顺序断言与现有实现不一致

**Step 3: 写最小实现**

- 扩展 `TransformResult` 增加普通文本推荐提示元数据
- 在 `plainText` 分支中给出推荐提示
- 调整 `secondaryActions` 顺序，让 `generateMD5` 排在最前

**Step 4: 重跑测试并确认通过**

Run: `swift test --filter TransformEngineTests`
Run: `swift test --filter SelectionTriggerPresentationFactoryTests`

Expected: 全部 PASS

### Task 3: 在 result panel 中渲染普通文本推荐提示与 MD5 主动作

**Files:**
- Modify: `/Users/sane/person/work-for-person/mac-tools/Sources/MacTextActionsApp/LiquidGlassPopover.swift`
- Modify: `/Users/sane/person/work-for-person/mac-tools/Tests/MacTextActionsAppTests/ToolContentLayoutTests.swift`
- Modify: `/Users/sane/person/work-for-person/mac-tools/Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift`

**Step 1: 写失败测试**

- 为普通文本 `actionsOnly` 状态补充推荐提示可见性的测试
- 为动作栏顺序补充 `MD5` 优先展示的测试

**Step 2: 运行相关测试并确认失败**

Run: `swift test --filter ToolContentLayoutTests`

Expected: 普通文本提示或动作栏结构断言失败

**Step 3: 写最小实现**

- 在 `LiquidGlassPopover` 的内容区增加普通文本推荐提示块
- 在 `actionsOnly` 状态下渲染可点击动作按钮
- 让第一个主按钮执行 `MD5`

**Step 4: 重跑测试并确认通过**

Run: `swift test --filter ToolContentLayoutTests`

Expected: PASS

### Task 4: 同步更新产品与 UI 文档

**Files:**
- Modify: `/Users/sane/person/work-for-person/mac-tools/README.md`
- Modify: `/Users/sane/person/work-for-person/mac-tools/docs/README.md`
- Modify: `/Users/sane/person/work-for-person/mac-tools/docs/product.md`
- Modify: `/Users/sane/person/work-for-person/mac-tools/docs/ui/mac-text-actions-ui.md`

**Step 1: 更新菜单模式与快捷键说明**

- 将顶部模式顺序改为 `自动识别`、`MD5`、`JSON Compress`
- 更新对应快捷键说明为 `⌘1` 到 `⌘3`

**Step 2: 更新普通文本交互规则**

- 明确普通文本不自动出结果
- 明确 `MD5` 是最突出推荐动作
- 保持 `JSON Compress` 作为显式模式与 `secondary action`

**Step 3: 通读并消除冲突文案**

- 确保入口文档、产品说明、UI 说明一致

### Task 5: 运行回归验证

**Files:**
- Test only

**Step 1: 运行核心测试**

Run: `swift test --filter MacTextActionsCoreTests`

**Step 2: 运行 App 侧相关测试**

Run: `swift test --filter StatusBarControllerTests`
Run: `swift test --filter ExecutionModeShortcutTests`
Run: `swift test --filter AppSettingsViewModelTests`
Run: `swift test --filter SelectionTriggerPresentationFactoryTests`
Run: `swift test --filter ToolContentLayoutTests`

**Step 3: 运行全量测试**

Run: `swift test`

Expected: 全部 PASS
