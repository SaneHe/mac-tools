# Mac Text Actions 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标：** 将现有窗口应用重构为 Raycast/Alfred 风格的弹出式工具，选中文字后按空格触发气泡

**架构：** 菜单栏 App + 状态栏图标 + 浮动气泡 + 左侧边栏设置窗口

**技术栈：** Swift 6, SwiftUI, AppKit (NSStatusItem, Accessibility API), 液态玻璃

---

## 文件结构

```
Sources/
├── MacTextActionsApp/
│   ├── App/
│   │   └── main.swift                      # App 入口（不用 @main）
│   ├── AppDelegate.swift                   # NSApplicationDelegate
│   ├── StatusBarController.swift           # 菜单栏图标管理
│   ├── SettingsWindowController.swift      # 设置窗口
│   ├── SettingsView.swift                  # 左侧边栏设置界面
│   ├── PopoverController.swift             # 浮动气泡控制器
│   ├── AccessibilityBridge.swift           # 读取选中文本 + 键盘监听
│   ├── KeyboardMonitor.swift                # 空格键监听
│   └── LiquidGlassPopover.swift             # 液态玻璃气泡视图
├── MacTextActionsApp/UI/
│   ├── SidebarView.swift                    # 左侧边栏
│   ├── ToolContentView.swift               # 工具内容区
│   └── Components/                          # 可复用组件
└── MacTextActionsCore/
    ├── ContentDetector.swift               # [已有] 内容检测
    ├── TransformEngine.swift               # [已有] 转换引擎
    ├── TransformSupport.swift             # [已有] 日期解析
    ├── Models.swift                        # [已有] 数据模型
    ├── UrlTransform.swift                  # [新增] URL 编解码
    └── SecondaryActionPerformer.swift      # [已有] 动作执行
```

---

## 任务清单

### Task 1: URL 编解码支持

**Files:**
- Create: `Sources/MacTextActionsCore/UrlTransform.swift`
- Modify: `Sources/MacTextActionsCore/TransformEngine.swift:22-29`
- Modify: `Sources/MacTextActionsCore/Models.swift:26-32`

- [ ] **Step 1: 创建 UrlTransform.swift**

```swift
import Foundation

public enum UrlTransform {
    public static func encode(_ input: String) -> String? {
        input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    public static func decode(_ input: String) -> String? {
        input.removingPercentEncoding
    }
}
```

- [ ] **Step 2: 更新 SecondaryAction 枚举**

在 `SecondaryAction` 中添加 `.urlEncode`, `.urlDecode`

- [ ] **Step 3: 更新 TransformEngine 支持 URL 操作**

在 `plainText` 分支的 `secondaryActions` 中添加 `.urlEncode`, `.urlDecode`

- [ ] **Step 4: 添加测试**

```swift
func testUrlEncode() {
    let input = "hello world"
    let result = UrlTransform.encode(input)
    assert(result == "hello%20world")
}

func testUrlDecode() {
    let input = "hello%20world"
    let result = UrlTransform.decode(input)
    assert(result == "hello world")
}
```

- [ ] **Step 5: 提交**

```bash
git add Sources/MacTextActionsCore/UrlTransform.swift Sources/MacTextActionsCore/TransformEngine.swift Sources/MacTextActionsCore/Models.swift
git commit -m "feat(core): add URL encode/decode transform"
```

---

### Task 2: App 入口和 AppDelegate 重构

**Files:**
- Create: `Sources/MacTextActionsApp/App/main.swift`
- Create: `Sources/MacTextActionsApp/AppDelegate.swift`
- Delete: `Sources/MacTextActionsApp/MacTextActionsApp.swift`

- [ ] **Step 1: 创建 main.swift**

```swift
import AppKit
import SwiftUI

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 2: 创建 AppDelegate.swift**

```swift
import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var popoverController: PopoverController?
    private var keyboardMonitor: KeyboardMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 Dock 图标
        NSApp.setActivationPolicy(.accessory)

        // 初始化状态栏
        statusBarController = StatusBarController()
        statusBarController?.onSettingsClicked = { [weak self] in
            self?.showSettings()
        }

        // 初始化气泡控制器
        popoverController = PopoverController()

        // 初始化键盘监听
        keyboardMonitor = KeyboardMonitor()
        keyboardMonitor?.onSpacePressed = { [weak self] in
            self?.handleSpaceTrigger()
        }
        keyboardMonitor?.start()

        // 请求辅助功能权限
        requestAccessibilityPermission()
    }

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func handleSpaceTrigger() {
        guard let selectedText = AccessibilityBridge.shared.readSelectedText() else {
            return
        }

        // 检测并显示气泡
        let detector = ContentDetector()
        let detection = detector.detect(selectedText)
        let engine = TransformEngine()
        let result = engine.transform(input: selectedText, detection: detection)

        popoverController?.show(with: result, selectedText: selectedText)
    }

    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
}
```

- [ ] **Step 3: 删除旧的 @main 文件**

- [ ] **Step 4: 提交**

```bash
git add Sources/MacTextActionsApp/App/main.swift Sources/MacTextActionsApp/AppDelegate.swift
git rm Sources/MacTextActionsApp/MacTextActionsApp.swift
git commit -m "refactor: convert to menu bar app with AppDelegate"
```

---

### Task 3: 状态栏控制器

**Files:**
- Create: `Sources/MacTextActionsApp/StatusBarController.swift`

- [ ] **Step 1: 创建 StatusBarController.swift**

```swift
import AppKit
import SwiftUI

final class StatusBarController {
    private var statusItem: NSStatusItem?
    var onSettingsClicked: (() -> Void)?

    init() {
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "Mac Text Actions")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "设置...", action: #selector(settingsClicked), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitClicked), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc private func settingsClicked() {
        onSettingsClicked?()
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add Sources/MacTextActionsApp/StatusBarController.swift
git commit -m "feat: add status bar controller for menu bar icon"
```

---

### Task 4: 键盘监听

**Files:**
- Create: `Sources/MacTextActionsApp/KeyboardMonitor.swift`

- [ ] **Step 1: 创建 KeyboardMonitor.swift**

```swift
import AppKit
import Carbon.HIToolbox

final class KeyboardMonitor {
    var onSpacePressed: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.handleKeyEvent(event)
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap = eventTap else {
            print("无法创建键盘事件监听")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }

    private func handleKeyEvent(_ event: CGEvent) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // 空格键 keyCode = 49
        if keyCode == 49 {
            DispatchQueue.main.async { [weak self] in
                self?.onSpacePressed?()
            }
        }
    }

    deinit {
        stop()
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add Sources/MacTextActionsApp/KeyboardMonitor.swift
git commit -m "feat: add keyboard monitor for space key detection"
```

---

### Task 5: 辅助功能桥接

**Files:**
- Create: `Sources/MacTextActionsApp/AccessibilityBridge.swift`

- [ ] **Step 1: 创建 AccessibilityBridge.swift**

```swift
import AppKit
import ApplicationServices

final class AccessibilityBridge {
    static let shared = AccessibilityBridge()

    private init() {}

    func readSelectedText() -> String? {
        guard let focusedElement = AXUIElementCreateSystemWide() as AXUIElement? else {
            return nil
        }

        var selectedTextValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )

        guard result == .success,
              let text = selectedTextValue as? String,
              !text.isEmpty else {
            return nil
        }

        return text
    }

    func replaceSelectedText(with newText: String) {
        guard let focusedElement = AXUIElementCreateSystemWide() as AXUIElement? else {
            return
        }

        var selectedTextValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )

        guard result == .success else { return }

        let selectionRange = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedTextValue
        )

        guard selectionRange == .success else { return }

        AXUIElementSetAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            newText as CFTypeRef
        )
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add Sources/MacTextActionsApp/AccessibilityBridge.swift
git commit -m "feat: add accessibility bridge for reading/replacing selected text"
```

---

### Task 6: 浮动气泡控制器

**Files:**
- Create: `Sources/MacTextActionsApp/PopoverController.swift`
- Create: `Sources/MacTextActionsApp/LiquidGlassPopover.swift`

- [ ] **Step 1: 创建 LiquidGlassPopover.swift**

```swift
import SwiftUI

struct LiquidGlassPopover: View {
    let result: TransformResult
    let selectedText: String
    let onCopy: () -> Void
    let onReplace: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(detectionTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Input preview
            Text(selectedText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(8)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(6)

            // Result
            if let output = result.primaryOutput {
                Text(output)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }

            // Error
            if result.displayMode == .error {
                Text(result.errorMessage ?? "未知错误")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }

            // Action buttons
            HStack(spacing: 8) {
                if result.primaryOutput != nil {
                    Button("复制") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(result.primaryOutput ?? "", forType: .string)
                        onCopy()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if result.secondaryActions.contains(.replaceSelection) {
                    Button("替换") {
                        AccessibilityBridge.shared.replaceSelectedText(with: result.primaryOutput ?? "")
                        onReplace()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var detectionTitle: String {
        switch result.displayMode {
        case .code: return "JSON 格式化"
        case .text: return "文本转换"
        case .error: return "转换失败"
        case .actionsOnly: return "可用操作"
        }
    }
}
```

- [ ] **Step 2: 创建 PopoverController.swift**

```swift
import AppKit
import SwiftUI

final class PopoverController {
    private var popover: NSPopover?
    private var eventMonitor: Any?

    func show(with result: TransformResult, selectedText: String) {
        if popover == nil {
            popover = NSPopover()
            popover?.behavior = .transient
            popover?.animates = true
        }

        let contentView = LiquidGlassPopover(
            result: result,
            selectedText: selectedText,
            onCopy: { [weak self] in
                self?.close()
            },
            onReplace: { [weak self] in
                self?.close()
            },
            onClose: { [weak self] in
                self?.close()
            }
        )

        popover?.contentViewController = NSHostingController(rootView: contentView)
        popover?.show(relativeTo: .zero, of: getFrontmostWindow()?.contentView ?? NSView(), preferredEdge: .maxY)

        // 添加鼠标点击外部关闭
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
    }

    func close() {
        popover?.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func getFrontmostWindow() -> NSWindow? {
        NSApp.orderedWindows.first { $0.isKeyWindow }
    }
}
```

- [ ] **Step 3: 提交**

```bash
git add Sources/MacTextActionsApp/PopoverController.swift Sources/MacTextActionsApp/LiquidGlassPopover.swift
git commit -m "feat: add popover controller with liquid glass UI"
```

---

### Task 7: 设置窗口（左侧边栏布局）

**Files:**
- Create: `Sources/MacTextActionsApp/SettingsWindowController.swift`
- Create: `Sources/MacTextActionsApp/SettingsView.swift`
- Create: `Sources/MacTextActionsApp/SidebarView.swift`
- Create: `Sources/MacTextActionsApp/ToolContentView.swift`

- [ ] **Step 1: 创建 SettingsWindowController.swift**

```swift
import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    convenience init() {
        let contentView = SettingsView()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Mac Text Actions"
        window.setContentSize(NSSize(width: 700, height: 500))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.center()

        self.init(window: window)
    }
}
```

- [ ] **Step 2: 创建 SettingsView.swift**

```swift
import SwiftUI

struct SettingsView: View {
    @State private var selectedTool: ToolType = .timestamp

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTool: $selectedTool)
                .frame(minWidth: 180)
        } detail: {
            ToolContentView(tool: selectedTool)
                .frame(minWidth: 400)
        }
        .navigationSplitViewStyle(.balanced)
    }
}
```

- [ ] **Step 3: 创建 SidebarView.swift**

```swift
import SwiftUI

enum ToolType: String, CaseIterable, Identifiable {
    case timestamp = "时间戳转换"
    case json = "JSON 格式化"
    case md5 = "MD5 加密"
    case url = "URL 编解码"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .timestamp: return "clock"
        case .json: return "curlybraces"
        case .md5: return "lock"
        case .url: return "link"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTool: ToolType

    var body: some View {
        List(ToolType.allCases) { tool in
            Button {
                selectedTool = tool
            } label: {
                Label(tool.rawValue, systemImage: tool.icon)
                    .foregroundColor(selectedTool == tool ? .accentColor : .primary)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selectedTool == tool ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(8)
        }
        .listStyle(.sidebar)
        .padding(8)
    }
}
```

- [ ] **Step 4: 创建 ToolContentView.swift**

```swift
import SwiftUI

struct ToolContentView: View {
    let tool: ToolType

    @State private var inputText: String = ""
    @State private var outputText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tool.rawValue)
                .font(.system(size: 20, weight: .semibold))

            TextField("输入内容...", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 100)

            HStack {
                Button("转换") {
                    performTransform()
                }
                .buttonStyle(.borderedProminent)

                Button("清空") {
                    inputText = ""
                    outputText = ""
                }

                Spacer()
            }

            if !outputText.isEmpty {
                Text("结果")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Text(outputText)
                    .font(.system(size: 13, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }

    private func performTransform() {
        switch tool {
        case .timestamp:
            let detector = ContentDetector()
            let detection = detector.detect(inputText)
            let engine = TransformEngine()
            let result = engine.transform(input: inputText, detection: detection)
            outputText = result.primaryOutput ?? result.errorMessage ?? ""

        case .json:
            let detector = ContentDetector()
            let detection = detector.detect(inputText)
            let engine = TransformEngine()
            let result = engine.transform(input: inputText, detection: detection)
            outputText = result.primaryOutput ?? result.errorMessage ?? ""

        case .md5:
            if let data = inputText.data(using: .utf8) {
                outputText = data.map { String(format: "%02x", $0) }.joined()
            }

        case .url:
            outputText = UrlTransform.encode(inputText) ?? "编码失败"
        }
    }
}
```

- [ ] **Step 5: 提交**

```bash
git add Sources/MacTextActionsApp/SettingsWindowController.swift Sources/MacTextActionsApp/SettingsView.swift Sources/MacTextActionsApp/SidebarView.swift Sources/MacTextActionsApp/ToolContentView.swift
git commit -m "feat: add settings window with sidebar layout"
```

---

### Task 8: 清理和集成

**Files:**
- Delete: `Sources/MacTextActionsApp/AppShellView.swift`
- Delete: `Sources/MacTextActionsApp/AppShellViewModel.swift`
- Delete: `Sources/MacTextActionsApp/WindowStyling.swift`
- Delete: `Sources/MacTextActionsApp/ResultPanelView.swift`
- Delete: `Sources/MacTextActionsApp/ResultPanelModels.swift`
- Modify: `Package.swift` (如需要)

- [ ] **Step 1: 删除废弃文件**

- [ ] **Step 2: 确保 Package.swift 配置正确**

确认 `MacTextActionsApp` 作为 executable target

- [ ] **Step 3: 构建测试**

```bash
swift build
```

- [ ] **Step 4: 提交**

```bash
git add -A
git commit -m "refactor: complete Raycast-style app architecture"
```

---

## 实施检查清单

| 任务 | 状态 | 说明 |
|------|------|------|
| Task 1: URL 编解码 | ⬜ | 核心功能扩展 |
| Task 2: App 入口重构 | ⬜ | 改为菜单栏 App |
| Task 3: 状态栏控制器 | ⬜ | 菜单栏图标 |
| Task 4: 键盘监听 | ⬜ | 空格键触发 |
| Task 5: 辅助功能桥接 | ⬜ | 读写选中文本 |
| Task 6: 气泡控制器 | ⬜ | 液态玻璃弹出 |
| Task 7: 设置窗口 | ⬜ | 左侧边栏布局 |
| Task 8: 清理和集成 | ⬜ | 最终构建测试 |
