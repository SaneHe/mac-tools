import AppKit
import SwiftUI
import MacTextActionsCore

struct SelectionTriggerPresentation {
    let selectedText: String
    let contentSource: SelectionContentSource
    let sourceMessage: String?
    let result: TransformResult
}

enum SelectionTriggerPresentationFactory {
    private enum ErrorMessage {
        static let noSelection = "未检测到可处理文本"
        static let unsupportedApplication = "当前应用暂不支持读取选中文本"
        static let permissionDenied = "请先在系统设置中开启辅助功能权限"
        static let clipboardFallback = "已改用剪贴板内容"
    }

    static func makePresentation(from selectionResult: SelectionReadResult) -> SelectionTriggerPresentation {
        switch selectionResult {
        case let .success(selectedText):
            return SelectionTriggerPresentation(
                selectedText: selectedText,
                contentSource: .selection,
                sourceMessage: nil,
                result: makeTransformResult(from: selectedText)
            )
        case let .fallbackSuccess(selectedText, _):
            return SelectionTriggerPresentation(
                selectedText: selectedText,
                contentSource: .clipboardFallback,
                sourceMessage: ErrorMessage.clipboardFallback,
                result: makeTransformResult(from: selectedText)
            )
        case let .failure(failure):
            return SelectionTriggerPresentation(
                selectedText: "",
                contentSource: .selection,
                sourceMessage: nil,
                result: makeErrorResult(for: failure)
            )
        }
    }

    private static func makeTransformResult(from selectedText: String) -> TransformResult {
        let detector = ContentDetector()
        let detection = detector.detect(selectedText)
        let engine = TransformEngine()
        return engine.transform(input: selectedText, detection: detection)
    }

    private static func makeErrorResult(for failure: SelectionReadFailure) -> TransformResult {
        TransformResult(
            primaryOutput: nil,
            secondaryActions: [],
            displayMode: .error,
            errorMessage: message(for: failure)
        )
    }

    private static func message(for failure: SelectionReadFailure) -> String {
        switch failure {
        case .noSelection:
            return ErrorMessage.noSelection
        case .unsupportedApplication:
            return ErrorMessage.unsupportedApplication
        case .permissionDenied:
            return ErrorMessage.permissionDenied
        }
    }
}

enum AppMainMenuBuilder {
    static func build(appName: String) -> NSMenu {
        let mainMenu = NSMenu(title: appName)
        mainMenu.addItem(makeApplicationMenuItem(appName: appName))
        mainMenu.addItem(makeEditMenuItem())
        mainMenu.addItem(makeWindowMenuItem())
        return mainMenu
    }

    private static func makeApplicationMenuItem(appName: String) -> NSMenuItem {
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: appName)

        let openWorkspaceItem = NSMenuItem(
            title: "打开工具",
            action: #selector(AppDelegate.openToolWorkspaceFromMainMenu(_:)),
            keyEquivalent: "o"
        )
        openWorkspaceItem.target = NSApp.delegate
        appMenu.addItem(openWorkspaceItem)

        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(AppDelegate.openSettingsFromMainMenu(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = NSApp.delegate
        appMenu.addItem(settingsItem)
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "隐藏 \(appName)",
                action: #selector(NSApplication.hide(_:)),
                keyEquivalent: "h"
            )
        )
        let hideOthersItem = NSMenuItem(
            title: "隐藏其他",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        )
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        appMenu.addItem(
            NSMenuItem(
                title: "显示全部",
                action: #selector(NSApplication.unhideAllApplications(_:)),
                keyEquivalent: ""
            )
        )
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "退出 \(appName)",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        appMenuItem.submenu = appMenu
        return appMenuItem
    }

    private static func makeEditMenuItem() -> NSMenuItem {
        let editMenuItem = NSMenuItem(title: "编辑", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "编辑")

        editMenu.addItem(NSMenuItem(title: "撤销", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(
            NSMenuItem(
                title: "重做",
                action: Selector(("redo:")),
                keyEquivalent: "Z"
            )
        )
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))

        editMenuItem.submenu = editMenu
        return editMenuItem
    }

    private static func makeWindowMenuItem() -> NSMenuItem {
        let windowMenuItem = NSMenuItem(title: "窗口", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "窗口")

        let closeItem = NSMenuItem(
            title: "关闭",
            action: #selector(AppDelegate.closeActiveWindow(_:)),
            keyEquivalent: "w"
        )
        closeItem.target = NSApp.delegate
        windowMenu.addItem(closeItem)

        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(
            NSMenuItem(
                title: "全部隐藏",
                action: #selector(NSApplication.hideOtherApplications(_:)),
                keyEquivalent: "h"
            )
        )

        windowMenuItem.submenu = windowMenu
        return windowMenuItem
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var toolWorkspaceWindow: NSWindow?
    private var popoverController: PopoverController?
    private var keyboardMonitor: KeyboardMonitor?
    private let permissionPrompter: PermissionPrompting = SystemPermissionPrompter()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 应用外观设置
        AppAppearanceSettings.shared.applyDockIconVisibility()

        NSApp.applicationIconImage = AppIconFactory.makeApplicationIcon()
        NSApp.mainMenu = AppMainMenuBuilder.build(appName: "Mac Text Actions")

        // 初始化状态栏
        statusBarController = StatusBarController()
        statusBarController?.setVisible(AppAppearanceSettings.shared.menuBarIconVisible)
        statusBarController?.onOpenWorkspaceClicked = { [weak self] in
            self?.showToolWorkspace()
        }
        statusBarController?.onSettingsClicked = { [weak self] in
            self?.showSettings()
        }

        // 监听菜单栏可见性变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMenuBarVisibilityChanged(_:)),
            name: .menuBarVisibilityChanged,
            object: nil
        )

        // 初始化气泡控制器
        popoverController = PopoverController()

        // 初始化键盘监听
        keyboardMonitor = KeyboardMonitor()
        keyboardMonitor?.onShortcutTriggered = { [weak self] in
            self?.handleSpaceTrigger()
        }
        keyboardMonitor?.start()

        // 请求辅助功能权限
        requestAccessibilityPermission()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        keyboardMonitor?.start()
    }

    @MainActor
    private func showSettings() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.settingsWindowController == nil {
                self.settingsWindowController = SettingsWindowController()
            }
            self.settingsWindowController?.window?.level = .normal
            self.settingsWindowController?.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @MainActor
    @objc func openSettingsFromMainMenu(_ sender: Any?) {
        showSettings()
    }

    @MainActor
    @objc func openToolWorkspaceFromMainMenu(_ sender: Any?) {
        showToolWorkspace()
    }

    @MainActor
    private func showToolWorkspace() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.toolWorkspaceWindow == nil {
                self.toolWorkspaceWindow = self.makeToolWorkspaceWindow()
            }
            self.toolWorkspaceWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @MainActor
    private func makeToolWorkspaceWindow() -> NSWindow {
        let hostingController = NSHostingController(rootView: ToolWorkspaceView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Mac Text Actions"
        window.setContentSize(NSSize(width: 1100, height: 760))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.toolbarStyle = .unifiedCompact
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.identifier = NSUserInterfaceItemIdentifier("toolWorkspaceWindow")
        return window
    }

    private func handleSpaceTrigger() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: AccessibilityBridge.shared.readSelectedTextResult()
        )

        popoverController?.show(
            with: presentation.result,
            selectedText: presentation.selectedText,
            contentSource: presentation.contentSource,
            sourceMessage: presentation.sourceMessage,
            statusItemButton: statusBarController?.statusItemButton
        )
    }

    private func requestAccessibilityPermission() {
        permissionPrompter.requestAccessibilityPermission()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 菜单栏应用，关闭窗口不退出应用
        return false
    }

    @objc private func handleMenuBarVisibilityChanged(_ notification: Notification) {
        guard let visible = notification.userInfo?["visible"] as? Bool else { return }
        statusBarController?.setVisible(visible)
    }

    @objc func closeActiveWindow(_ sender: Any?) {
        guard let window = NSApp.keyWindow else { return }

        if window.identifier == NSUserInterfaceItemIdentifier("toolWorkspaceWindow") {
            toolWorkspaceWindow?.close()
        } else if window.identifier == NSUserInterfaceItemIdentifier("settingsWindow") {
            settingsWindowController?.close()
        } else {
            window.close()
        }
    }
}
