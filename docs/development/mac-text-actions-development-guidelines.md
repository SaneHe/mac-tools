# Mac Text Actions 开发规范

## 1. 目标
本规范用于统一 `Mac Text Actions` 的 Swift 开发风格、工程组织、依赖策略和 UI 实现约定。目标不是堆砌通用最佳实践，而是为当前 macOS 工具项目建立稳定、可执行的工程基线。

## 2. 参考来源与采用策略
本项目参考以下社区主流实践，但不会机械照搬：
- `Airbnb Swift Style Guide`
- `Google Swift Style Guide`
- `Ray Wenderlich / Kodeco Swift Style Guide`
- `Apple Human Interface Guidelines`

采用策略如下：
- 命名、可读性、不可变优先、函数粒度等代码规则参考 `Airbnb`
- 文件组织、`MARK` 分区、扩展拆分参考 `Ray Wenderlich`
- 一致性和长期维护性参考 `Google`
- UI 和交互以上位原则遵循 `Apple HIG`

## 3. Swift 代码规范
### 3.1 命名
- 命名应表达完整意图，优先可读性
- 函数名应描述行为，而不是实现细节
- 不使用含糊缩写，除非是行业通用缩写

示例：

```swift
let selectedText: String
func fetchUserProfile(userID: String)
func transformTimestampToLocalDate(_ value: String) -> String?
```

### 3.2 不可变优先
- 优先使用 `let`
- 仅在状态确实会变化时使用 `var`
- 避免无意义的可选类型和过宽的可变范围

### 3.3 函数设计
- 函数保持短小
- 单一职责
- 避免在一个函数中同时做识别、转换、UI 更新和副作用执行

### 3.4 类型与状态
- 领域状态优先使用明确枚举，而不是魔法字符串
- 错误状态应可枚举、可测试、可展示

### 3.5 注释
- 注释只解释“为什么”，不重复“做了什么”
- 优先写清模块边界和特殊系统行为

## 4. 文件组织规范
### 4.1 文件职责
- 一个文件只承载一个主要类型或一组紧密相关的扩展
- `View`、`ViewModel`、`Service`、`Model` 分开存放

### 4.2 分区
- 使用 `MARK` 分区组织文件结构

示例：

```swift
// MARK: - Lifecycle
// MARK: - State
// MARK: - Actions
// MARK: - Layout
// MARK: - Helpers
```

### 4.3 Extension 使用
- 用 `extension` 按能力拆分较大的类型
- 不用 `extension` 隐藏本应独立成服务的复杂逻辑

## 5. 架构与并发约定
### 5.1 架构
- 采用 `MVVM + Services`
- `View` 只负责渲染和事件转发
- `ViewModel` 负责状态和用户动作编排
- `Service` 负责系统桥接、识别、转换和副作用能力

### 5.2 并发
- 优先使用 `async/await`
- 非必要不引入 `Combine` 作为首选异步方案
- UI 更新必须保持主线程一致性

### 5.3 系统桥接
- `SwiftUI` 负责主要界面
- `AppKit` 负责：
  - `global shortcut`
  - 窗口与浮层控制
  - `selected text` 读取
  - `Replace Selection`
- 系统桥接逻辑不得直接散落在 `View` 中

## 6. 依赖策略
### 6.1 默认原则
- 先系统框架，后第三方依赖
- 没有明确价值，不新增依赖

### 6.2 当前推荐
- `SwiftUI`
- `AppKit`
- `Foundation`
- `EventKit`
- `SwiftLint`

### 6.3 当前不建议默认引入
- `Alamofire`
- `Kingfisher`
- `Hero`
- `Tokamak`
- `SwiftUIX`

这些库与当前项目核心问题不直接匹配，容易引入额外复杂度。

## 7. SwiftLint 规范
- 项目开始编码后应启用 `SwiftLint`
- 用于约束：
  - 文件长度
  - 函数长度
  - 命名一致性
  - 强制解包控制
  - 空行和导入顺序

建议规则目标：
- 保持代码整洁
- 发现明显坏味道
- 不把 lint 变成压制正常表达的工具

## 8. UI 与交互实现规范
### 8.1 上位原则
- 遵循 `Apple HIG`
- 优先清晰、层级、一致性、反馈

### 8.2 SwiftUI 视图约定
- 避免 `VStack` / `HStack` 无限制嵌套
- 复杂区块拆成小型可复用 `View`
- `View` 中不直接写大段业务判断
- 状态保持单一来源

### 8.3 当前项目的 UI 风格落地
- 原生 macOS 工具感
- 轻材质或半透明浮层
- 主结果居中突出
- 二级动作收拢在底部
- 不做网页应用式卡片工作台

## 9. 测试与质量要求
- 识别逻辑应可单元测试
- 转换逻辑应可单元测试
- 错误状态映射应可单元测试
- `macOS 13` 下重点验证：
  - `global shortcut`
  - 浮层窗口
  - `selected text`
  - `Replace Selection`

## 10. 本项目推荐组合
- 语言：`Swift 6`
- UI：`SwiftUI`
- 系统桥接：`AppKit`
- 架构：`MVVM + Services`
- 异步：`async/await`
- 规范：`SwiftLint + Apple HIG + 项目级约定`

## 11. CI 与发布流程约定
### 11.1 GitHub Actions
- 仓库使用 `GitHub Actions` 执行基础工程自动化
- 工作流运行环境当前统一使用 GitHub 官方仍受支持的 `macos-15-intel` runner，避免继续依赖已退役的 `macos-13` 标签，并在未产出 `Universal` 包前保持发布产物对 `Intel Mac` 的兼容性
- `CI` 工作流负责在 `push` 和 `pull_request` 时运行 `swift test` 与 `swift build`
- `Release` 工作流负责在以下场景构建可下载产物并发布到 `GitHub Release`：
  - 推送 `v*` tag
  - 手动触发
  - 向 `master` 推送且最新提交信息包含 `tag:vX.Y.Z` 或 `[tag:vX.Y.Z]`
- 当 `Release` 工作流由 `master` 的普通 `push` 触发且检测到版本号时，会先创建远程 tag，并由该 tag 的 `push` 事件触发真正的 release 构建与发布，避免同一版本进入重复发布链路

### 11.2 当前发布策略
- 当前仓库仍以 `Swift Package` 作为实现基础
- 在未引入正式 `Xcode archive`、签名和公证链路前，发布产物为未签名的 macOS `.app` 压缩包
- 该产物适合个人开发、自测或可信范围内分发，不应视为面向公开用户的正式发行包

### 11.2.1 提交信息触发发布约定
- 仅当最新提交信息显式包含 `tag:vX.Y.Z` 或 `[tag:vX.Y.Z]` 时，`master` 分支的 `push` 才会触发自动发布
- 推荐将版本标记直接附加在提交标题或正文中，例如：`feat: 补充设置页权限引导 [tag:v0.1.0]`
- 若提交信息中未包含合法版本号，`Release` 工作流会直接跳过后续发布步骤
- 若远程 tag 不存在，工作流会先创建该 tag，再由 tag 触发的工作流继续发布
- 若远程 tag 已存在，分支 `push` 工作流不会重复创建或重复发布，真正的 release 构建应由该 tag 的 `push` 或手动触发继续执行
- 手动触发 `Release` 时应提供已存在的远程 tag，工作流会切换到该 tag 对应的提交进行构建，避免 release 记录与产物来源不一致

### 11.3 未签名产物限制
- `macOS` 可能在首次打开时阻止运行未签名、未公证应用
- 如需运行，通常需要在系统的 `隐私与安全性` 中手动放行
- 当项目进入公开分发阶段时，应补齐：
  - `Developer ID` 签名
  - `Apple notarization`
  - 更完整的 `.app` / `.dmg` 打包链路
