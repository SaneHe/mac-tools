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
- 首次启动时，若缺少 `辅助功能` 或 `输入监听` 授权，应用会先进入独立的权限引导窗口；在两项权限完成前不能进入正常使用态
- 设置窗口是独立窗口，只展示 `global shortcut`、状态栏菜单内 `⌘1` 到 `⌘3` 的模式切换职责、权限状态与重新检查入口
- `global shortcut` 负责真正执行当前默认模式；状态栏菜单中的 `⌘1` 到 `⌘3` 只在菜单展开时生效，用于切换默认模式
- 状态栏菜单模式顺序固定为：`自动识别`、`MD5`、`JSON Compress`
- 模式切换快捷键与菜单顺序一一对应：`自动识别 = ⌘1`、`MD5 = ⌘2`、`JSON Compress = ⌘3`
- `创建提醒事项` 功能实现保留，但当前不在顶部菜单栏和模式切换快捷键中暴露入口
- 自动识别已能稳定命中的 `JSON`、时间戳和日期字符串不再单独占用顶部模式入口；顶部菜单只保留 `自动识别` 与需要显式强制执行的模式
- 普通文本在自动识别下仍不直接生成 `primary result`，但会将 `MD5` 作为最突出、默认优先的推荐动作
- 对带 option 的二次操作统一使用底部动作栏切换，不在输入区额外放 `Toggle`；当前 `MD5` 使用 `转大写 / 转小写`，`日期转时间戳` 使用 `转毫秒 / 转秒级`
- 所有复制入口统一显示底部居中的 `已复制` HUD，包括工具页复制按钮、`result panel` 复制按钮和结果文本双击复制
- `result panel` 中点击复制后先显示短暂确认反馈，再自动关闭浮层，避免成功状态一闪而过
- 首启强制引导只覆盖 `辅助功能` 与 `输入监听`；`提醒事项` 继续按需单独授权
- 权限提示需要明确区分辅助功能相关能力、输入监听与提醒事项授权，不能让失败表现为静默无响应

## 当前状态
- 已有 `MacTextActionsCore` 与 `MacTextActionsApp` 两层代码结构
- 当前实现以主流程和结果面板为核心，文档已完成一轮精简合并
- 本次与 option 型二次操作相关的聚焦测试已在当前环境通过；完整 `swift test` 仍需结合仓库里其他并行改动继续核对
