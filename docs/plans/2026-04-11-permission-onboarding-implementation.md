# 首启权限引导 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为应用增加强制性的首启权限引导窗口，在 `辅助功能` 与 `输入监听` 未完成前阻止进入正常使用态。

**Architecture:** 新增独立的权限引导视图模型、SwiftUI 视图和窗口控制器，由 `AppDelegate` 统一执行启动门禁。权限状态继续复用现有的 `PermissionStatusProviding` / `PermissionPrompting` 抽象，确保测试可以通过 stub 隔离系统依赖。

**Tech Stack:** Swift 6、SwiftUI、AppKit、XCTest

---

### Task 1: 写入首批失败测试

**Files:**
- Create: `Tests/MacTextActionsAppTests/PermissionOnboardingTests.swift`
- Modify: `Tests/MacTextActionsAppTests/SettingsWindowControllerTests.swift`

**Step 1: Write the failing test**

- 为权限引导视图模型写测试，覆盖：
  - 任一权限缺失时不可继续
  - 两项权限都完成时可继续
  - 触发授权后会调用对应的 prompt
  - 继续动作会进行最终检查
- 为权限引导窗口控制器写构建测试

**Step 2: Run test to verify it fails**

Run: `swift test --filter PermissionOnboardingTests`
Expected: FAIL，提示相关类型尚未定义

**Step 3: Write minimal implementation**

- 暂不写实现，本任务只负责让测试先红灯

**Step 4: Run test to verify it fails correctly**

Run: `swift test --filter PermissionOnboardingTests`
Expected: FAIL，且失败原因聚焦在缺少类型或行为

### Task 2: 实现权限引导视图模型与窗口

**Files:**
- Create: `Sources/MacTextActionsApp/PermissionOnboarding.swift`
- Modify: `Sources/MacTextActionsApp/SettingsWindowController.swift`
- Test: `Tests/MacTextActionsAppTests/PermissionOnboardingTests.swift`

**Step 1: Write the failing test**

- 为以下行为补测试或补断言：
  - 刷新状态后文本与按钮态正确更新
  - 窗口根视图使用独立的权限引导视图

**Step 2: Run test to verify it fails**

Run: `swift test --filter PermissionOnboardingTests`
Expected: FAIL

**Step 3: Write minimal implementation**

- 新增权限引导状态枚举、视图模型、SwiftUI 视图
- 新增独立窗口控制器
- 复用现有权限状态与请求抽象

**Step 4: Run test to verify it passes**

Run: `swift test --filter PermissionOnboardingTests`
Expected: PASS

### Task 3: 接入启动门禁

**Files:**
- Modify: `Sources/MacTextActionsApp/AppDelegate.swift`
- Modify: `Sources/MacTextActionsApp/KeyboardMonitor.swift`
- Test: `Tests/MacTextActionsAppTests/PermissionOnboardingTests.swift`

**Step 1: Write the failing test**

- 补应用门禁测试，覆盖：
  - 缺权限时不启动键盘监听
  - 缺权限时打开工具或设置会回到权限引导
  - 完成权限后才启动监听

**Step 2: Run test to verify it fails**

Run: `swift test --filter PermissionOnboardingTests`
Expected: FAIL

**Step 3: Write minimal implementation**

- 在 `AppDelegate` 中加入门禁判断与窗口切换逻辑
- 将键盘监听启动时机后移到权限通过之后

**Step 4: Run test to verify it passes**

Run: `swift test --filter PermissionOnboardingTests`
Expected: PASS

### Task 4: 同步设置页与文档

**Files:**
- Modify: `Sources/MacTextActionsApp/SettingsView.swift`
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/ui/mac-text-actions-ui.md`
- Modify: `docs/implementation.md`

**Step 1: Write the failing test**

- 若设置页文案测试需要补充，则先加测试断言

**Step 2: Run test to verify it fails**

Run: `swift test --filter SettingsViewModelTests`
Expected: FAIL（如新增文案断言）

**Step 3: Write minimal implementation**

- 调整设置页权限文案，明确首启存在强制引导
- 更新相关文档描述

**Step 4: Run test to verify it passes**

Run: `swift test --filter SettingsViewModelTests`
Expected: PASS

### Task 5: 全量验证

**Files:**
- Modify: `Tests/MacTextActionsAppTests/PermissionOnboardingTests.swift`（如需补漏）

**Step 1: Run focused tests**

Run: `swift test --filter PermissionOnboardingTests`
Expected: PASS

**Step 2: Run related regression tests**

Run: `swift test --filter SettingsViewModelTests`
Expected: PASS

Run: `swift test --filter SettingsWindowControllerTests`
Expected: PASS

Run: `swift test --filter KeyboardMonitorTests`
Expected: PASS

**Step 3: Run broader verification**

Run: `swift test`
Expected: PASS
