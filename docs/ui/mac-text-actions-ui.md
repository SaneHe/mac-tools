# Mac Text Actions UI 说明

本文档只保留 UI 本身需要长期维护的规则。产品行为以 [product.md](../product.md) 为准，技术边界以 [implementation.md](../implementation.md) 为准。

## 1. 设计方向

- 风格方向：`Native macOS utility panel + refined polish`
- 目标：轻量、克制、立即反馈，不抢占用户当前上下文
- 原则：`primary result` 是视觉中心，`secondary action` 靠近结果但不喧宾夺主
- 不采用网页工具台、重品牌工作台或命令列表优先的视觉模型

## 2. 视觉基调

- 主字体使用 `SF Pro`
- 结构化结果使用等宽字体
- 使用轻材质或半透明浮层背景，色彩以系统中性色为主
- 错误态使用低饱和状态色，不做大面积高对比警告块
- 动效只保留短促的显隐和状态切换
- `result panel` 显示采用窗帘展开动画，从上往下展开，使用 SwiftUI `mask` 和 spring 动画实现
- 应用图标与状态栏图标共享 `text cursor + sparkles` 的图形语义

## 3. 信息架构

- 常驻层：状态栏菜单、独立设置窗口
- 主交互层：`result panel`
- 补充工作区：独立工具窗口
- 系统动作层：复制、替换、提醒事项创建

## 4. 状态栏菜单

- 状态栏菜单采用单层模式列表，不做分组或二级子菜单
- 菜单项顺序固定为：`自动识别`、`JSON 格式化`、`JSON Compress`、`时间戳转本地时间`、`日期转时间戳`、`MD5`、`创建提醒事项`
- 当前默认模式使用勾选态表示
- 菜单项名称后显示 `⌘1` 到 `⌘7` 对应快捷键
- 快捷键映射固定为：`自动识别 = ⌘1`、`创建提醒事项 = ⌘2`、`JSON 格式化 = ⌘3`、`JSON Compress = ⌘4`、`时间戳转本地时间 = ⌘5`、`日期转时间戳 = ⌘6`、`MD5 = ⌘7`
- `创建提醒事项` 虽然是低频模式，仍固定放在菜单最后，同时保留 `⌘2`
- 菜单内 `⌘1` 到 `⌘7` 只在菜单展开时生效，用于切换默认模式，不直接执行动作
- 顶部应用菜单和状态栏菜单中的“设置...”都应打开同一个独立设置窗口

## 5. 设置窗口

- 设置窗口独立打开，不与工具操作页混排
- 该窗口只承担“快捷键与权限”职责，不承载时间戳转换、JSON 或 MD5 等功能
- 主体保留一张“快捷键与权限”信息卡，集中展示：
  - 当前 `global shortcut`
  - 状态栏菜单内 `⌘1` 到 `⌘7` 的模式切换职责
  - 辅助功能相关权限状态
  - 提醒事项授权状态
  - 重新检查或引导入口
- 快捷键支持录制和修改，并实时更新显示
- 权限提示需要明确说明失败原因，不能只给一个模糊的不可用状态

## 6. Result Panel

### 6.1 布局
- 顶部：执行来源、类型标签、原文摘要
- 顶部辅助信息：`selected text` 或 `clipboard fallback` 来源标签
- 中部：`primary result` 或错误信息
- 底部：复制、替换和类型相关 `secondary action`

### 6.2 表现原则
- 面板宽度按内容长度采用固定档位，不做连续拉伸
- 时间结果保持紧凑，`JSON` 和较长文本允许更宽档位
- 头部区域保持紧凑，操作按钮偏小巧
- 内容区域优先给结果留空间，背景透明度偏低，维持轻盈感

### 6.3 状态
```mermaid
stateDiagram-v2
    [*] --> Loading
    Loading --> NoSelection
    Loading --> UnsupportedApp
    Loading --> JsonResult
    Loading --> TimestampResult
    Loading --> DateResult
    Loading --> PlainTextActions
    Loading --> InvalidJson

    JsonResult --> CompressedJson
    PlainTextActions --> Md5Result
    PlainTextActions --> ReminderFlow
    JsonResult --> CopyAction
    TimestampResult --> CopyAction
    DateResult --> CopyAction
    Md5Result --> CopyAction
```

## 7. 不同内容类型的 UI 行为

### 7.1 JSON
- 使用代码块风格展示格式化结果
- 默认主动作是 `Copy Result`
- 附加动作为 `JSON Compress` 和 `Replace Selection`

### 7.2 时间戳 / 日期字符串
- 使用高可读文本样式展示转换结果
- 可附带简短补充说明，如本地时间
- 默认主动作是 `Copy Result`

### 7.3 普通文本
- 不自动生成 `primary result`
- 直接展示可执行动作
- 常见动作为 `MD5` 和 `Create Reminder`

### 7.4 错误状态
- 错误信息必须简洁且明确
- 不隐藏失败原因
- 发生 `clipboard fallback` 时，必须明确提示“不是当前实时选区”

## 8. 键盘行为

- `Esc`：关闭 `result panel`
- `global shortcut`：按当前默认模式执行主流程
- `⌘1` 到 `⌘7`：仅在状态栏菜单展开时切换默认模式
- `Cmd+Enter`：执行当前工具主动作
- `Cmd+Delete`：清空当前输入与结果
- `Cmd+C`：复制当前结果

## 9. 不推荐方向

- 不做网页应用风格面板
- 不做重彩色卡片式工具台
- 不做复杂多页签或深层侧边栏结构
- 不做以命令搜索为中心的主交互模型
