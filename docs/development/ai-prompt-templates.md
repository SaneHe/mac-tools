# Mac Text Actions AI Prompt 模板

## 1. 使用原则
这些模板用于辅助生成与本项目一致的代码、设计和调试输出。模板必须服从当前仓库约束，不得覆盖已有产品边界、技术选型和交互规则。

使用时默认附带以下上下文：
- 项目为 macOS 原生工具
- 技术栈为 `Swift 6 + SwiftUI + AppKit bridge`
- 架构为 `MVVM + Services`
- UI 风格为 `Native macOS utility panel + refined polish`
- `v1` 不包含剪贴板管理、剪贴板回退和自动写回

## 2. 代码生成模板
```text
你是一个资深 macOS Swift 工程师。

请基于以下项目约束生成代码：
- 技术栈：Swift 6 + SwiftUI + AppKit bridge
- 架构：MVVM + Services
- 风格：原生 macOS 工具感，遵循 Apple HIG
- 项目规则：
  - global shortcut 驱动
  - 只处理 selected text
  - JSON 默认只做格式化
  - MD5 是 secondary action
  - 不做 clipboard fallback

需求：
- 功能：
- 输出范围：

要求：
- 代码结构清晰
- View 不承载系统桥接逻辑
- 尽量使用 async/await
- 必要时补充简短注释说明为什么这样做

输出：
1. 完整代码
2. 关键设计说明
3. 可能的风险点
```

## 3. UI 设计模板
```text
你是一个 macOS UI/UX 设计专家。

请为这个原生工具设计界面：
- 平台：macOS
- 风格：Native macOS utility panel + refined polish
- 原则：Apple HIG、结果优先、层级清晰、反馈明确
- 技术前提：SwiftUI + AppKit bridge

页面或组件：
- 功能：

要求：
- 不做网页应用工作台风格
- 不做复杂侧边栏
- primary result 是视觉中心
- secondary action 收敛在底部

输出：
- UI 结构
- 状态说明
- SwiftUI 组件拆分建议
- 视觉建议
```

## 4. 调试模板
```text
你是一个 Swift / AppKit / SwiftUI 调试专家。

以下代码或行为存在问题：
<代码或现象描述>

请帮我：
1. 判断问题更可能出在 SwiftUI、AppKit bridge、状态管理还是系统权限
2. 找出 bug 或根因
3. 提供修复方案
4. 给出验证步骤
```

## 5. 架构优化模板
```text
你是 macOS 架构专家。

请在以下约束下优化项目结构：
- Swift 6
- SwiftUI + AppKit bridge
- MVVM + Services
- 面向 macOS 13+

当前代码或结构：
<代码或目录结构>

请输出：
1. 当前问题
2. 重构建议
3. 模块职责调整
4. 是否值得引入更多抽象
```

## 6. 系统集成模板
```text
你是 macOS 系统集成专家。

我需要实现以下能力：
- global shortcut
- 读取 selected text
- Replace Selection
- Reminders integration

请基于 Swift 6 + AppKit bridge 给出：
1. 推荐实现路径
2. 涉及的系统权限
3. 在 macOS 13 和 macOS 14+ 上的兼容性注意事项
4. 不推荐的实现方式
```
