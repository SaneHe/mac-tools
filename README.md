# Mac Text Actions

`Mac Text Actions` 是一个面向 `macOS` 的文本处理工具，围绕当前 `selected text` 提供快速识别、转换和后续动作能力。主流程由 `global shortcut` 触发，在无法直接读取选区时允许 `clipboard fallback`，并明确标注内容来源，避免把旧剪贴板内容误认为实时选区。

当前仓库同时包含产品文档和基于 `Swift 6`、`SwiftUI`、`AppKit`、`MVVM + Services` 的原生实现代码。产品边界与交互规则以 [docs/product.md](./docs/product.md) 为准，技术方向与模块边界以 [docs/implementation.md](./docs/implementation.md) 为准。

## 仓库概览
- 当前仓库已经不只是文档集合，包含 `MacTextActionsCore` 与 `MacTextActionsApp` 两层实现
- `docs/` 已收敛为少量核心文档，避免同一规则在多处重复维护
- 若你是第一次接手此仓库，建议从 [docs/README.md](./docs/README.md) 开始阅读

## 仓库结构
- `Sources/MacTextActionsCore`：检测、转换、次要动作等核心逻辑
- `Sources/MacTextActionsApp`：应用壳层、结果面板、窗口与预览相关实现
- `Tests/`：核心逻辑与界面状态映射测试
- `docs/`：精简后的产品、实现、UI 和开发规范文档
- `AGENTS.md`：仓库协作规则与文档维护约束

## 文档入口
- [docs/README.md](./docs/README.md)：文档索引和阅读顺序
- [docs/product.md](./docs/product.md)：产品定位、范围、主流程、识别规则
- [docs/implementation.md](./docs/implementation.md)：技术基线、模块边界、数据流和验证要求
- [docs/ui/mac-text-actions-ui.md](./docs/ui/mac-text-actions-ui.md)：状态栏菜单、设置窗口、`result panel` 的 UI 约束

## 设置、快捷键与权限
- 设置窗口是独立窗口，只展示 `global shortcut`、状态栏菜单内 `⌘1` 到 `⌘7` 的模式切换职责、权限状态与重新检查入口
- `global shortcut` 负责真正执行当前默认模式；状态栏菜单中的 `⌘1` 到 `⌘7` 只在菜单展开时生效，用于切换默认模式
- 状态栏菜单模式顺序固定为：`自动识别`、`JSON 格式化`、`JSON Compress`、`时间戳转本地时间`、`日期转时间戳`、`MD5`、`创建提醒事项`
- 权限提示需要明确区分辅助功能相关能力和提醒事项授权，不能让失败表现为静默无响应

## 当前状态
- 已有 `MacTextActionsCore` 与 `MacTextActionsApp` 两层代码结构
- 当前实现以主流程和结果面板为核心，文档已完成一轮精简合并
- 本地 `swift test` 仍受当前机器 `Command Line Tools / macOS SDK` 配置影响，现阶段不能在该环境下声明测试全部通过
