# Mac Text Actions

`Mac Text Actions` 是一个面向 `macOS` 的文本处理工具，优先围绕当前 `selected text` 提供快速识别、转换和后续动作能力，在无法读取选区时支持 `clipboard fallback`，并使用 `global shortcut` 触发主流程。

当前仓库已经不只是文档集合，包含一套基于 `Swift 6`、`SwiftUI`、`AppKit`、`MVVM + Services` 的实现骨架，以及核心检测、转换和结果面板相关代码。

## 当前状态
- 产品范围和架构方向以 [docs/README.md](./docs/README.md) 及其下属文档为准
- 已包含 `MacTextActionsCore` 与 `MacTextActionsApp` 两层代码结构
- 已补充核心模块注释、`MARK` 分区和维护约束
- 面向用户的错误提示、状态文案和主要界面文案已统一为中文
- 已补充部分测试覆盖文案与状态映射
- 设置已拆分为独立窗口，仅承载”快捷键与权限说明”；工具工作区单独承载”时间戳转换 / JSON / MD5 / URL”等功能页面
- `Space` 为全局触发入口，`Ctrl+1` 到 `Ctrl+4` 用于工具工作区内切换工具，顶部应用菜单与状态栏菜单中的”设置...”统一打开独立设置窗口
- 支持自定义全局快捷键，可在设置窗口中录制和修改触发快捷键
- 弹框显示采用窗帘展开动画效果，从上往下展开，使用 SwiftUI mask 和 spring 动画实现
- UI 布局经过优化：弹框头部更紧凑、操作按钮更小巧、内容区域显示更多文本、背景更轻盈通透

## 仓库结构
- `Sources/MacTextActionsCore`：检测、转换、次要动作等核心业务逻辑
- `Sources/MacTextActionsApp`：结果面板、应用壳层、预览服务和窗口配置
- `Tests/`：核心逻辑与 app 层状态映射测试
- `docs/`：产品、设计、方案、架构、交互、UI 与开发规范文档
- `AGENTS.md`：仓库协作约束、术语、开发原则与维护规则

## 开发基线
- 开发语言：`Swift 6`
- UI 技术：`SwiftUI + AppKit`
- 架构模式：`MVVM + Services`
- 最低支持系统：`macOS 13 Ventura`
- 推荐开发环境：`Xcode 16+`

## 最近维护记录
- 为核心与 app 层源码补充维护型注释，覆盖模块职责、关键分支和窗口桥接说明
- 在 `AGENTS.md` 中增加注释维护要求，以及面向对象、`SOLID`、`KISS`、`DRY` 等开发原则
- 将核心错误提示、错误态文案、按钮文案、动作名称和演示文案统一为中文
- 新增 app 层测试目标与部分文案相关测试
- 已将原混合页面拆分为”独立设置窗口 + 独立工具工作区”，避免设置说明与功能操作混排
- 已新增代码生成的应用图标与状态栏模板图，统一 `text cursor + sparkles` 图形语言
- 新增窗帘展开动画效果，弹框显示时采用从上往下展开的动画，使用 SwiftUI 的 mask 和 spring 动画实现
- UI 布局优化：弹框头部更紧凑、操作按钮更小巧、内容区域显示更多文本、背景更轻盈通透
- 支持自定义全局快捷键，可在设置窗口中录制和修改触发快捷键

## 当前已知问题
- 本地执行 `swift test` 仍受当前机器的 `Command Line Tools / macOS SDK` 配置影响，`xcrun --sdk macosx --show-sdk-platform-path` 无法正确返回 `PlatformPath`
- 因此，现阶段可以确认文档和源码已更新，但不能在当前环境下声明测试全部通过

## 文档入口
- 项目文档入口： [docs/README.md](./docs/README.md)
