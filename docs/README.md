# Mac Text Actions Docs

这套文档描述 `Mac Text Actions` 工具型应用的 `v1` 方案，覆盖产品需求、产品设计、方案选型、技术架构、交互流程、UI 设计与开发协作约束，供产品、设计和工程协作使用。

## 当前项目状态
- 当前仓库已包含源代码，不再只是文档仓库
- 已落地的代码结构分为：
  - `Sources/MacTextActionsCore`：检测、转换、次要动作等核心逻辑
  - `Sources/MacTextActionsApp`：结果面板、应用壳层、预览服务和窗口样式
  - `Tests/`：核心逻辑与 app 层状态映射测试
- 当前实现仍以演示和架构骨架为主，产品行为和边界仍以本目录下文档为准

## 最近维护记录
- 已为主要源码补充维护型注释，说明模块职责、关键分支和平台桥接点
- 已在仓库协作规则中补充注释维护要求，以及面向对象、`SOLID`、`KISS`、`DRY` 等开发原则
- 已将当前源码中的用户可见错误文案、状态文案和主要界面文案统一为中文
- 已新增部分测试，覆盖核心错误文案和结果面板状态映射
- 已明确设置窗口仅承担快捷键与权限说明职责，工具工作区独立承载时间戳转换等功能页面
- `global shortcut` 是当前默认模式的唯一全局执行入口
- 状态栏菜单提供单层模式列表：`自动识别`、`JSON 格式化`、`JSON Compress`、`时间戳转本地时间`、`日期转时间戳`、`MD5`、`创建提醒事项`
- 菜单展开时支持 `⌘1` 到 `⌘7` 切换默认模式，并在菜单项名称后直接显示快捷键，其中 `自动识别 = ⌘1`、`创建提醒事项 = ⌘2`、`JSON 格式化 = ⌘3`、`JSON Compress = ⌘4`、`时间戳转本地时间 = ⌘5`、`日期转时间戳 = ⌘6`、`MD5 = ⌘7`；其中“创建提醒事项”作为较低频模式固定放在菜单最后。顶部应用菜单与状态栏菜单中的”设置...”统一打开独立设置窗口
- 已补充应用图标与状态栏图标的统一视觉说明，图形语义围绕 `text cursor + sparkles`
- 新增窗帘展开动画效果，弹框显示时采用从上往下展开的动画，使用 SwiftUI 的 mask 和 spring 动画实现
- UI 布局优化：弹框头部高度减少更紧凑、”复制”和”替换”按钮尺寸精简更小巧、内容区域高度增加显示更多文本、文本框背景透明度降低更轻盈通透
- 支持自定义全局快捷键，可在设置窗口中录制和修改触发快捷键
- 当前环境下 `swift test` 仍受本机 `Command Line Tools / macOS SDK` 配置问题影响，需单独处理工具链后再完成完整验证

## 文档索引
- [需求文档](./requirements/mac-text-actions-prd.md)
- [设计文档](./design/mac-text-actions-design.md)
- [方案文档](./solution/mac-text-actions-solution.md)
- [技术架构](./architecture/mac-text-actions-architecture.md)
- [交互流程](./interaction/mac-text-actions-interaction-flow.md)
- [UI 设计](./ui/mac-text-actions-ui.md)
- [开发规范](./development/mac-text-actions-development-guidelines.md)
- [AI Prompt 模板](./development/ai-prompt-templates.md)

## 统一术语
- `global shortcut`：全局快捷键
- `selected text`：当前选中文本
- `result panel`：结果浮层
- `primary result`：默认自动计算并展示的主结果
- `secondary action`：用户显式触发的二级动作

## v1 范围
- 通过 `global shortcut` 触发主流程（支持自定义快捷键）
- 优先处理当前 `selected text`
- 在无法读取 `selected text` 时支持 `clipboard fallback`
- `clipboard fallback` 会在读取失败时自动触发复制回退，并明确提示其不是直接读取到的实时选区
- 支持 `JSON` 格式化与合法性校验
- 支持时间戳与日期字符串互转
- `MD5` 为 `secondary action`
- 支持快速创建 macOS 提醒事项
- 支持复制结果、替换原文
- 弹框显示采用窗帘展开动画效果

## 技术选型
- 开发语言：`Swift 6`
- UI 框架：`SwiftUI`
- 系统桥接：`AppKit`
- 架构模式：`MVVM + Services`
- UI 风格：`Native macOS utility panel + refined polish`

## 兼容性基线
- 最低支持系统：`macOS 13 Ventura`
- 推荐运行环境：`macOS 14+`
- 推荐开发环境：`Xcode 16+`
- 硬件目标：优先支持 `Apple Silicon`，建议产出 `Universal` 包兼容 `Intel Mac`
- 权限依赖：辅助功能相关权限、提醒事项授权
- `macOS 13` 需要重点验证全局快捷键、浮层窗口、选区读取和替换原文链路

## 明确不包含
- 剪贴板管理
- 自动写回原文
- 多步骤工作流
- 提醒事项自然语言时间解析

## 阅读建议
- 如果你刚接手这个仓库，先读根目录 `README.md` 了解当前代码与文档状态
- 先看 [需求文档](./requirements/mac-text-actions-prd.md) 理解产品目标和范围
- 再看 [设计文档](./design/mac-text-actions-design.md) 和 [交互流程](./interaction/mac-text-actions-interaction-flow.md) 了解体验和规则
- 然后看 [技术架构](./architecture/mac-text-actions-architecture.md) 与 [UI 设计](./ui/mac-text-actions-ui.md) 作为实现输入
- 最后参考 [开发规范](./development/mac-text-actions-development-guidelines.md) 和 [AI Prompt 模板](./development/ai-prompt-templates.md) 统一开发方式
