# Shortcut Recovery And Safe Replace Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 提升 `global shortcut` 长时间运行时的恢复稳定性，并让 `Replace Selection` 始终作用于原始目标上下文而不是当前面板焦点。

**Architecture:** 先用测试锁定两条高风险链路，再把快捷键监听中的 event tap 生命周期抽成可恢复、可观测的单元，并在应用生命周期事件里补恢复触发点。替换链路则通过在读取 `selected text` 时同时捕获原始辅助功能目标引用，后续替换直接写回该目标，避免面板激活后焦点漂移。

**Tech Stack:** `Swift 6`、`SwiftUI`、`AppKit`、`ApplicationServices`、`XCTest`、`OSLog`

---

### Task 1: 为快捷键恢复场景建立失败测试

**Files:**
- Modify: `Tests/MacTextActionsAppTests/KeyboardMonitorTests.swift`
- Modify: `Sources/MacTextActionsApp/KeyboardMonitor.swift`

**Step 1: 写失败测试**

补三类测试：
- 当收到 `tapDisabledByTimeout` 时，会走统一恢复入口，而不是仅保留静态判断。
- 当收到 `tapDisabledByUserInput` 时，同样会触发恢复。
- 当监听对象被要求 `ensureActive` 时，如果当前监听无效，会重新创建监听。

测试应优先通过注入的恢复计数器或测试替身验证行为，而不是依赖真实系统 event tap。

**Step 2: 运行测试确认失败**

Run: `swift test --filter KeyboardMonitorTests`
Expected: 新增测试失败，提示恢复入口或状态探测能力不存在。

**Step 3: 写最小实现**

在 `KeyboardMonitor` 中：
- 引入可测试的 tap 状态抽象或内部恢复钩子
- 暴露最小的 `ensureActive()` 能力
- 将禁用事件统一路由到单一恢复逻辑

**Step 4: 运行测试确认通过**

Run: `swift test --filter KeyboardMonitorTests`
Expected: `KeyboardMonitorTests` 全绿

**Step 5: 提交**

```bash
git add Tests/MacTextActionsAppTests/KeyboardMonitorTests.swift Sources/MacTextActionsApp/KeyboardMonitor.swift
git commit -m "test: 补充快捷键监听恢复场景测试"
```

### Task 2: 实现快捷键监听完整恢复与生命周期兜底

**Files:**
- Modify: `Sources/MacTextActionsApp/KeyboardMonitor.swift`
- Modify: `Sources/MacTextActionsApp/AppDelegate.swift`
- Modify: `Tests/MacTextActionsAppTests/KeyboardMonitorTests.swift`

**Step 1: 写失败测试**

新增测试覆盖：
- 恢复逻辑会在必要时完整重建 event tap，而不是只调用 `tapEnable`
- 应用重新激活后会调用监听保障逻辑
- 生命周期通知到来时不会重复创建多个监听源

如需新增测试替身，可直接放在现有测试文件中。

**Step 2: 运行测试确认失败**

Run: `swift test --filter KeyboardMonitorTests`
Expected: 新增恢复/重建相关断言失败

**Step 3: 写最小实现**

实现要点：
- 将 event tap 创建、run loop source 安装、销毁逻辑收口到统一方法
- 恢复时优先完整重建监听
- 为 `AppDelegate` 增加重新激活和系统唤醒后的 `ensureActive` 兜底
- 保证不会因为多次恢复留下重复 source
- 使用轻量 `Logger` 记录恢复事件，但不要记录用户原文内容

**Step 4: 运行测试确认通过**

Run: `swift test --filter KeyboardMonitorTests`
Expected: `KeyboardMonitorTests` 全绿

**Step 5: 提交**

```bash
git add Sources/MacTextActionsApp/KeyboardMonitor.swift Sources/MacTextActionsApp/AppDelegate.swift Tests/MacTextActionsAppTests/KeyboardMonitorTests.swift
git commit -m "fix: 提升全局快捷键监听恢复稳定性"
```

### Task 3: 为安全替换链路建立失败测试

**Files:**
- Modify: `Tests/MacTextActionsAppTests/AccessibilityBridgeTests.swift`
- Modify: `Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift`
- Modify: `Sources/MacTextActionsApp/AccessibilityBridge.swift`
- Modify: `Sources/MacTextActionsApp/AppDelegate.swift`

**Step 1: 写失败测试**

补以下测试：
- 读取成功时会同时返回替换所需的原始目标上下文
- 触发 `clipboard fallback` 时不会伪造可替换目标
- 替换动作会优先写回捕获时的目标，而不是重新读取当前焦点
- 当没有可替换目标时，替换能力应被移除或转为失败可感知状态

**Step 2: 运行测试确认失败**

Run: `swift test --filter AccessibilityBridgeTests`
Expected: 新增测试失败，提示当前结果模型没有替换目标上下文

**Step 3: 写最小实现**

实现要点：
- 引入表示读取快照/替换目标的轻量模型
- `SelectionReadResult.success` 携带原始 `AXUIElement` 目标引用或其封装
- `fallbackSuccess` 明确不提供直接替换目标
- `SelectionTriggerPresentation` / `PopoverController` 透传替换目标

**Step 4: 运行测试确认通过**

Run: `swift test --filter AccessibilityBridgeTests`
Expected: `AccessibilityBridgeTests` 全绿

**Step 5: 提交**

```bash
git add Sources/MacTextActionsApp/AccessibilityBridge.swift Sources/MacTextActionsApp/AppDelegate.swift Tests/MacTextActionsAppTests/AccessibilityBridgeTests.swift Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift
git commit -m "test: 补充安全替换链路测试"
```

### Task 4: 实现安全替换与回归验证

**Files:**
- Modify: `Sources/MacTextActionsApp/AccessibilityBridge.swift`
- Modify: `Sources/MacTextActionsApp/AppDelegate.swift`
- Modify: `Sources/MacTextActionsApp/PopoverController.swift`
- Modify: `Sources/MacTextActionsApp/LiquidGlassPopover.swift`
- Modify: `Tests/MacTextActionsAppTests/AccessibilityBridgeTests.swift`
- Modify: `Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift`
- Modify: `docs/implementation.md`
- Modify: `docs/product.md`

**Step 1: 写失败测试**

如果 Task 3 还未覆盖完整用户路径，再补一条从 presentation 到 popover 行为的测试：
- 当内容来自 `clipboard fallback` 或没有原始替换目标时，不应展示可误导的 `Replace Selection`
- 当存在原始目标时，替换动作使用原始目标写回

**Step 2: 运行测试确认失败**

Run: `swift test --filter SelectionTriggerPresentationFactoryTests`
Expected: 新增的替换能力断言失败

**Step 3: 写最小实现**

实现要点：
- `TransformResult` 或 presentation 层区分“是否允许替换”
- `PopoverController` 的替换闭包改为使用捕获目标执行写回
- 无法安全替换时，底部不展示 `Replace Selection`，或明确给出失败提示
- 文档同步说明：只有存在安全写回目标时才暴露替换动作；`clipboard fallback` 不应暗示可直接写回实时选区

**Step 4: 运行测试与回归**

Run:
- `swift test --filter KeyboardMonitorTests`
- `swift test --filter AccessibilityBridgeTests`
- `swift test --filter SelectionTriggerPresentationFactoryTests`
- `swift test`

Expected:
- 目标测试全部通过
- 全量测试通过

**Step 5: 提交**

```bash
git add Sources/MacTextActionsApp/AccessibilityBridge.swift Sources/MacTextActionsApp/AppDelegate.swift Sources/MacTextActionsApp/PopoverController.swift Sources/MacTextActionsApp/LiquidGlassPopover.swift Tests/MacTextActionsAppTests/AccessibilityBridgeTests.swift Tests/MacTextActionsAppTests/SelectionTriggerPresentationFactoryTests.swift docs/product.md docs/implementation.md
git commit -m "fix: 保障安全替换并收敛结果面板行为"
```
