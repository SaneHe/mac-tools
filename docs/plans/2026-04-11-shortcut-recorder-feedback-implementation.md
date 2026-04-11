# 快捷键录制反馈 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为设置页的快捷键录制交互增加录制中即时显示、绑定成功提示和稳定的监听生命周期管理。

**Architecture:** 在现有 `ShortcutRecorderRow` 基础上补一层轻量录制状态机，把“默认态 / 录制态 / 成功态”收敛到同一个 SwiftUI 组件内部。将按键识别与监听注册从匿名闭包堆叠改成可控生命周期的事件监控，并通过测试覆盖快捷键显示、状态过渡与设置同步链路。

**Tech Stack:** `Swift 6`、`SwiftUI`、`AppKit`、`XCTest`

---

### Task 1: 为快捷键文案和显示逻辑补测试基线

**Files:**
- Modify: `Tests/MacTextActionsAppTests/SettingsViewModelTests.swift`
- Modify: `Sources/MacTextActionsApp/ShortcutConfiguration.swift`

**Step 1: Write the failing test**

在 `Tests/MacTextActionsAppTests/SettingsViewModelTests.swift` 增加针对快捷键显示文案的测试，覆盖：

```swift
func testShortcutDisplayStringUsesModifierSymbolsAndReadableKeyName() {
    let configuration = ShortcutConfiguration(
        keyCode: 49,
        modifiers: [.option, .shift]
    )

    XCTAssertEqual(configuration.displayString, "⌥+⇧+Space")
}

func testShortcutDisplayStringUsesReadableLetterKeyName() {
    let configuration = ShortcutConfiguration(
        keyCode: 0,
        modifiers: [.command]
    )

    XCTAssertEqual(configuration.displayString, "⌘+A")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter SettingsViewModelTests`

Expected: FAIL，因为当前 `keyCodeToName(_:)` 对普通键位的映射不正确，字母键不会显示为预期结果。

**Step 3: Write minimal implementation**

在 `Sources/MacTextActionsApp/ShortcutConfiguration.swift` 中：
- 提取统一的按键显示辅助方法，例如 `static func displayName(for keyCode: Int64) -> String`
- 修正常见字母键与特殊键的显示映射
- 保持 `Space`、方向键、回车等现有特殊键显示

参考实现骨架：

```swift
private static let keyDisplayNames: [Int64: String] = [
    0: "A",
    1: "S",
    2: "D",
    3: "F",
    5: "G",
    6: "Z",
    7: "X",
    8: "C",
    9: "V",
    49: "Space"
]
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter SettingsViewModelTests`

Expected: PASS，对应新增的快捷键显示测试通过。

**Step 5: Commit**

```bash
git add Tests/MacTextActionsAppTests/SettingsViewModelTests.swift Sources/MacTextActionsApp/ShortcutConfiguration.swift
git commit -m "test: cover shortcut display names"
```

### Task 2: 为录制态提取可测试的输入识别逻辑

**Files:**
- Create: `Tests/MacTextActionsAppTests/ShortcutRecorderLogicTests.swift`
- Modify: `Sources/MacTextActionsApp/ShortcutSettingsView.swift`

**Step 1: Write the failing test**

新建 `Tests/MacTextActionsAppTests/ShortcutRecorderLogicTests.swift`，先为录制输入识别规则写测试：

```swift
func testRecorderIgnoresModifierOnlyKeyPress() {
    let result = ShortcutRecorderLogic.capture(
        keyCode: 56,
        modifierFlags: [.shift]
    )

    XCTAssertNil(result)
}

func testRecorderBuildsConfigurationForValidShortcut() {
    let result = ShortcutRecorderLogic.capture(
        keyCode: 49,
        modifierFlags: [.option, .shift]
    )

    XCTAssertEqual(
        result,
        ShortcutConfiguration(keyCode: 49, modifiers: [.option, .shift])
    )
}

func testRecorderTreatsEscapeAsCancel() {
    XCTAssertEqual(
        ShortcutRecorderLogic.interpretControlKey(keyCode: 53),
        .cancel
    )
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ShortcutRecorderLogicTests`

Expected: FAIL，因为 `ShortcutRecorderLogic` 还不存在。

**Step 3: Write minimal implementation**

在 `Sources/MacTextActionsApp/ShortcutSettingsView.swift` 中先提取一个轻量逻辑类型，例如：

```swift
enum ShortcutRecorderControlAction {
    case cancel
}

enum ShortcutRecorderLogic {
    static func capture(keyCode: Int64, modifierFlags: NSEvent.ModifierFlags) -> ShortcutConfiguration? { ... }
    static func interpretControlKey(keyCode: Int64) -> ShortcutRecorderControlAction? { ... }
    static func isModifierKey(_ keyCode: Int64) -> Bool { ... }
}
```

要求：
- 单独修饰键返回 `nil`
- 只有包含至少一个修饰键的普通键才返回 `ShortcutConfiguration`
- `Esc` 被识别为取消操作

**Step 4: Run test to verify it passes**

Run: `swift test --filter ShortcutRecorderLogicTests`

Expected: PASS，输入识别逻辑测试通过。

**Step 5: Commit**

```bash
git add Tests/MacTextActionsAppTests/ShortcutRecorderLogicTests.swift Sources/MacTextActionsApp/ShortcutSettingsView.swift
git commit -m "test: cover shortcut recorder logic"
```

### Task 3: 实现录制态即时显示与成功提示

**Files:**
- Modify: `Sources/MacTextActionsApp/ShortcutSettingsView.swift`
- Modify: `Tests/MacTextActionsAppTests/SettingsViewModelTests.swift`

**Step 1: Write the failing test**

先在 `Tests/MacTextActionsAppTests/SettingsViewModelTests.swift` 添加一个轻量状态模型测试入口。若当前文件不适合承载，可新建视图模型测试文件，但保持同一任务最小范围。测试目标：

```swift
func testShortcutRecorderStatusMessageUsesBoundShortcutAfterSuccess() {
    let feedback = ShortcutRecorderFeedback.success(
        ShortcutConfiguration(keyCode: 49, modifiers: [.option])
    )

    XCTAssertEqual(feedback.message, "快捷键已绑定为 ⌥+Space")
}
```

如果实现时选择创建独立测试文件，也可以改成：

```swift
func testShortcutRecorderSuccessMessageIncludesDisplayString() { ... }
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ShortcutRecorder`

Expected: FAIL，因为成功反馈模型或文案构造还不存在。

**Step 3: Write minimal implementation**

在 `Sources/MacTextActionsApp/ShortcutSettingsView.swift` 中：
- 为 `ShortcutRecorderRow` 增加状态：
  - `isRecording`
  - `recordingPreview`
  - `feedback`
- 将原本只显示 `configuration.displayString` 的胶囊改成按状态显示：
  - 默认态：当前快捷键
  - 录制态未输入：`请按下新的快捷键`
  - 录制态已识别：即时显示识别到的组合键
  - 成功态：在行内显示 `快捷键已绑定为 ...`
- 点击“修改”进入录制态时清空旧反馈
- 点击“取消”或收到取消按键时退出录制态且保留原值

建议抽一个轻量反馈类型，避免把文案散落在 `body` 内：

```swift
private struct ShortcutRecorderFeedback: Equatable {
    let message: String

    static func success(_ configuration: ShortcutConfiguration) -> Self {
        .init(message: "快捷键已绑定为 \(configuration.displayString)")
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ShortcutRecorder`

Expected: PASS，成功反馈文案测试通过。

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/ShortcutSettingsView.swift Tests/MacTextActionsAppTests/SettingsViewModelTests.swift
git commit -m "feat: show shortcut recording feedback"
```

### Task 4: 把事件监听改成单一可控生命周期

**Files:**
- Modify: `Sources/MacTextActionsApp/ShortcutSettingsView.swift`
- Modify: `Tests/MacTextActionsAppTests/ShortcutRecorderLogicTests.swift`

**Step 1: Write the failing test**

为监听生命周期抽象写测试，避免视图每次 `onAppear` 都叠加本地事件监听。可以通过协议隔离监控注册器：

```swift
func testRecorderStartsMonitorOnlyOnceWhileRecording() {
    let monitor = LocalEventMonitorSpy()
    let coordinator = ShortcutRecordingCoordinator(eventMonitor: monitor)

    coordinator.startRecording()
    coordinator.startRecording()

    XCTAssertEqual(monitor.startCallCount, 1)
}

func testRecorderStopsMonitorWhenRecordingEnds() {
    let monitor = LocalEventMonitorSpy()
    let coordinator = ShortcutRecordingCoordinator(eventMonitor: monitor)

    coordinator.startRecording()
    coordinator.finishRecording()

    XCTAssertEqual(monitor.stopCallCount, 1)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ShortcutRecorderLogicTests`

Expected: FAIL，因为还没有事件监听协调器和测试替身。

**Step 3: Write minimal implementation**

在 `Sources/MacTextActionsApp/ShortcutSettingsView.swift` 中：
- 提取本地事件监听协调器，例如 `ShortcutRecordingCoordinator`
- 用可保存 token 的方式管理 `NSEvent.addLocalMonitorForEvents`
- 录制开始时注册一次
- 录制结束、取消或视图消失时移除监听

实现要点：

```swift
protocol LocalEventMonitoring {
    func start(handler: @escaping (NSEvent) -> NSEvent?) 
    func stop()
}
```

生产实现里用 `NSEvent.addLocalMonitorForEvents` / `NSEvent.removeMonitor`；测试里用 spy 统计调用次数。

**Step 4: Run test to verify it passes**

Run: `swift test --filter ShortcutRecorderLogicTests`

Expected: PASS，监听生命周期测试通过。

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/ShortcutSettingsView.swift Tests/MacTextActionsAppTests/ShortcutRecorderLogicTests.swift
git commit -m "refactor: manage shortcut recorder monitor lifecycle"
```

### Task 5: 确保设置页与全局快捷键配置同步

**Files:**
- Modify: `Sources/MacTextActionsApp/SettingsView.swift`
- Modify: `Sources/MacTextActionsApp/ShortcutSettings.swift`
- Modify: `Tests/MacTextActionsAppTests/SettingsViewModelTests.swift`

**Step 1: Write the failing test**

在 `Tests/MacTextActionsAppTests/SettingsViewModelTests.swift` 中补一个设置同步测试：

```swift
func testUpdatingShortcutConfigurationUpdatesSummaryDisplay() {
    let permissionStatusProvider = PermissionStatusProviderStub(
        accessibilityAuthorized: true,
        inputMonitoringAuthorized: true
    )
    let viewModel = AppSettingsViewModel(
        permissionStatusProvider: permissionStatusProvider
    )

    viewModel.shortcutConfiguration = ShortcutConfiguration(
        keyCode: 49,
        modifiers: [.control]
    )

    XCTAssertEqual(viewModel.globalShortcutDisplayValue, "⌃+Space")
}
```

如果当前实现未把 `viewModel.shortcutConfiguration` 写回 `ShortcutSettingsManager.shared.configuration`，这个测试会暴露出摘要与持久化不同步的问题。

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppSettingsViewModelTests`

Expected: FAIL 或暴露逻辑缺口，因为当前 `ShortcutRecorderRow` 绑定的是 `viewModel.shortcutConfiguration`，但视图模型没有统一的更新入口和同步副作用。

**Step 3: Write minimal implementation**

在 `Sources/MacTextActionsApp/SettingsView.swift` 中：
- 为 `AppSettingsViewModel` 增加统一更新方法，例如 `updateShortcutConfiguration(_:)`
- 在更新时同步写入 `ShortcutSettingsManager.shared.configuration`
- 让 `ShortcutRecorderRow` 使用这个更新入口，而不是只改本地 `@Published` 值

如有必要，在 `Sources/MacTextActionsApp/ShortcutSettings.swift` 中补充便于测试的更新钩子，避免多处散落写入逻辑。

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppSettingsViewModelTests`

Expected: PASS，设置摘要和配置更新链路保持一致。

**Step 5: Commit**

```bash
git add Sources/MacTextActionsApp/SettingsView.swift Sources/MacTextActionsApp/ShortcutSettings.swift Tests/MacTextActionsAppTests/SettingsViewModelTests.swift
git commit -m "fix: sync shortcut settings with app settings view model"
```

### Task 6: 更新文档并完成回归验证

**Files:**
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/ui/mac-text-actions-ui.md`

**Step 1: Write the failing doc expectation**

先检查三个文档里“设置页 UI 风格说明、快捷键职责和权限提示规则”是否已经同步描述快捷键录制反馈。如果没有，把本次新增行为作为需要补齐的文档项：

```markdown
- 点击“修改”后进入录制态，界面即时显示识别到的组合键
- 绑定成功后展示轻量行内提示
```

**Step 2: Run verification pass before edits**

Run: `rg -n "录制|绑定成功|快捷键已绑定" README.md docs/README.md docs/ui/mac-text-actions-ui.md`

Expected: 搜索结果不完整，说明文档尚未覆盖这次行为变更。

**Step 3: Write minimal documentation updates**

分别在以下文件补充一致描述：
- `README.md`
- `docs/README.md`
- `docs/ui/mac-text-actions-ui.md`

要求：
- 用中文
- 使用统一术语 `global shortcut`
- 明确“即时显示按下的组合键”与“行内成功提示”

**Step 4: Run tests and doc verification**

Run: `swift test --filter ShortcutRecorder`

Expected: PASS，快捷键录制相关测试通过。

Run: `swift test --filter AppSettingsViewModelTests`

Expected: PASS，设置同步测试通过。

Run: `rg -n "录制|绑定成功|快捷键已绑定" README.md docs/README.md docs/ui/mac-text-actions-ui.md`

Expected: 三个入口文档都能检索到本次交互描述。

**Step 5: Commit**

```bash
git add README.md docs/README.md docs/ui/mac-text-actions-ui.md
git commit -m "docs: document shortcut recorder feedback flow"
```
