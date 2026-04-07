# App Icon Refresh Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 `Mac Text Actions` 的应用图标与状态栏图标重绘为更贴合“选中文本处理”语义的版本，并保持当前构建链路可直接使用。

**Architecture:** 继续沿用运行时代码生成图标的方式，在 `AppIconFactory` 内重构背景、文本卡片、`text cursor` 与 `sparkles` 的绘制逻辑。测试侧通过采样渲染后的像素颜色验证关键视觉特征，同时保留现有尺寸与模板渲染断言，避免只凭肉眼判断。

**Tech Stack:** `Swift 6`、`AppKit`、`XCTest`

---

### Task 1: 建立图标视觉回归测试

**Files:**
- Modify: `Tests/MacTextActionsAppTests/AppIconFactoryTests.swift`
- Test: `Tests/MacTextActionsAppTests/AppIconFactoryTests.swift`

**Step 1: 写失败测试**
- 新增应用图标视觉特征测试：
  - 中央区域应呈现深蓝色 `cursor`
  - 右上动作区域应存在暖黄色 `sparkles`
- 保留现有尺寸与模板图断言

**Step 2: 运行测试确认失败**

Run: `swift test --filter AppIconFactoryTests`
Expected: 新增视觉断言失败，说明当前图标不符合新方案

**Step 3: 补充最小测试辅助代码**
- 在测试文件内增加像素采样辅助方法
- 将辅助方法拆成小函数，避免单个方法过长

**Step 4: 再次运行测试**

Run: `swift test --filter AppIconFactoryTests`
Expected: 仍然因旧图标绘制结果不符而失败，但辅助方法本身工作正常

### Task 2: 重绘应用与状态栏图标

**Files:**
- Modify: `Sources/MacTextActionsApp/AppIconFactory.swift`
- Test: `Tests/MacTextActionsAppTests/AppIconFactoryTests.swift`

**Step 1: 最小实现新图标结构**
- 提取新的常量组，替换旧的循环箭头与徽章图形
- 绘制蓝色渐变底板、错位文本卡片、居中 `cursor` 和右上 `sparkles`
- 将状态栏图标替换为简化的 `cursor + sparkle` 模板图

**Step 2: 运行目标测试**

Run: `swift test --filter AppIconFactoryTests`
Expected: 新增视觉断言通过，现有尺寸与模板断言继续通过

**Step 3: 清理与注释**
- 为非直观的绘制分层补充简洁中文注释
- 确保函数职责清晰，单个函数保持小而专注

### Task 3: 完成验证

**Files:**
- Modify: `Sources/MacTextActionsApp/AppIconFactory.swift`
- Modify: `Tests/MacTextActionsAppTests/AppIconFactoryTests.swift`

**Step 1: 运行聚焦测试**

Run: `swift test --filter AppIconFactoryTests`
Expected: `AppIconFactoryTests` 全部通过

**Step 2: 运行完整构建**

Run: `swift build`
Expected: 构建成功，说明图标工厂修改未破坏应用编译

**Step 3: 记录结果**
- 若测试与构建均成功，整理验证结果
- 若受本机 SDK 环境影响失败，记录具体命令与失败信息，避免误报
