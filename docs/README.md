# Mac Text Actions Docs

`docs/` 目录已整理为少量核心文档，尽量把同一条规则收敛到单一位置，减少来回跳转和重复维护。

## 文档索引
- [product.md](./product.md)：产品定位、范围、主流程、识别优先级、错误与回退规则
- [implementation.md](./implementation.md)：技术基线、模块边界、数据流、兼容性与验证要求
- [ui/mac-text-actions-ui.md](./ui/mac-text-actions-ui.md)：状态栏菜单、设置窗口、`result panel` 的 UI 说明
- [development/mac-text-actions-development-guidelines.md](./development/mac-text-actions-development-guidelines.md)：Swift、架构、测试和工程规范
- [development/ai-prompt-templates.md](./development/ai-prompt-templates.md)：AI 协作提示模板

## 阅读顺序
- 先读根目录 [README.md](../README.md) 了解仓库现状
- 再看 [product.md](./product.md) 理解产品范围和交互规则
- 然后看 [implementation.md](./implementation.md) 与 [ui/mac-text-actions-ui.md](./ui/mac-text-actions-ui.md) 作为实现输入
- 最后参考开发规范和 AI 模板统一协作方式

## 文档职责
- [product.md](./product.md) 是产品行为、范围、检测优先级和错误规则的权威来源
- [implementation.md](./implementation.md) 是技术基线、模块边界和验证要求的权威来源
- [ui/mac-text-actions-ui.md](./ui/mac-text-actions-ui.md) 负责状态栏菜单、设置窗口和 `result panel` 的 UI 落地说明
- 本页只负责文档导航、术语和少量必要摘要，不重复展开完整产品规则

## 统一术语
- `global shortcut`：全局快捷键
- `selected text`：当前选中文本
- `result panel`：结果浮层
- `primary result`：默认自动计算并展示的主结果
- `secondary action`：用户显式触发的二级动作

## 项目快照
- `v1` 是围绕 `selected text` 的轻量 macOS 文本动作工具
- 主流程由 `global shortcut` 触发，支持自定义
- 详细产品范围、识别优先级和错误规则统一见 [product.md](./product.md)

## 设置、快捷键与权限
- 首次启动时，若缺少 `辅助功能` 或 `输入监听` 权限，应用先进入独立权限引导窗口；两项完成前不进入正常使用态
- 设置窗口只负责“快捷键与权限”，不承载工具功能
- 状态栏菜单只负责切换默认模式和打开设置
- 菜单展开时可用 `⌘1` 到 `⌘3` 切换默认模式，映射固定为：`自动识别 = ⌘1`、`MD5 = ⌘2`、`JSON Compress = ⌘3`
- 模式顺序固定为：`自动识别`、`MD5`、`JSON Compress`
- `创建提醒事项` 能力保留，但当前不作为状态栏菜单默认模式暴露
- 顶部菜单不再重复暴露自动识别已可稳定命中的能力，`JSON`、时间戳和日期字符串统一回归 `自动识别`
- 普通文本在自动识别下不直接产出结果，但会优先推荐 `MD5`
- 需要二次切换或附带 option 的功能，统一复用底部 `secondary action` 切换规则；当前 `MD5` 与 `日期转时间戳` 已按此处理
- 所有复制入口统一复用底部居中的 `已复制` HUD，工具页、`result panel` 与结果文本双击复制保持一致
- `result panel` 的复制确认先展示短促反馈，再关闭浮层，不直接在点击瞬间消失
- `Replace Selection` 只在当前结果持有可安全写回的原始目标时展示；`clipboard fallback` 结果不会暴露替换入口
- `clipboard fallback` 成功后会尽量恢复用户原有剪贴板；但若用户或其他程序已更新剪贴板，则不会反向覆盖该新内容
- 首启强制引导只覆盖 `辅助功能` 与 `输入监听`；`提醒事项` 继续保留按需授权
- 权限提示必须清楚区分辅助功能相关能力、输入监听与提醒事项授权，不能把失败表现成静默无响应
