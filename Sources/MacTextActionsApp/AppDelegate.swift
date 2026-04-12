import AppKit
import SwiftUI
import MacTextActionsCore

struct SelectionTriggerPresentation {
    let title: String
    let selectedText: String
    let contentSource: SelectionContentSource
    let sourceMessage: String?
    let result: TransformResult
    let transformContext: TransformContext
}

enum SelectionTriggerPresentationFactory {
    private enum ErrorMessage {
        static let noSelection = "未检测到可处理文本"
        static let unsupportedApplication = "当前应用暂不支持读取选中文本"
        static let permissionDenied = "请先在系统设置中开启辅助功能权限"
        static let clipboardFallback = "已改用剪贴板内容，不是当前实时选区"
    }

    static func makePresentation(
        from selectionResult: SelectionReadResult,
        mode: ExecutionMode = .automatic
    ) -> SelectionTriggerPresentation {
        switch selectionResult {
        case let .success(selectedText):
            let context = makeTransformContext(for: mode, selectedText: selectedText)
            return SelectionTriggerPresentation(
                title: makePresentationTitle(for: mode, selectedText: selectedText),
                selectedText: selectedText,
                contentSource: .selection,
                sourceMessage: nil,
                result: makeTransformResult(from: selectedText, mode: mode, context: context),
                transformContext: context
            )
        case let .fallbackSuccess(selectedText, _):
            let context = makeTransformContext(for: mode, selectedText: selectedText)
            return SelectionTriggerPresentation(
                title: makePresentationTitle(for: mode, selectedText: selectedText),
                selectedText: selectedText,
                contentSource: .clipboardFallback,
                sourceMessage: ErrorMessage.clipboardFallback,
                result: makeTransformResult(from: selectedText, mode: mode, context: context),
                transformContext: context
            )
        case let .failure(failure):
            return SelectionTriggerPresentation(
                title: makeErrorTitle(for: mode),
                selectedText: "",
                contentSource: .selection,
                sourceMessage: nil,
                result: makeErrorResult(for: failure),
                transformContext: TransformContext()
            )
        }
    }

    static func makeResult(
        from selectedText: String,
        mode: ExecutionMode,
        context: TransformContext
    ) -> TransformResult {
        if let result = makeExplicitModeResult(from: selectedText, mode: mode, context: context) {
            return result
        }

        let detector = ContentDetector()
        let detection = detector.detect(selectedText)
        let engine = TransformEngine()
        return engine.transform(input: selectedText, detection: detection, context: context)
    }

    private static func makeTransformResult(
        from selectedText: String,
        mode: ExecutionMode,
        context: TransformContext
    ) -> TransformResult {
        makeResult(from: selectedText, mode: mode, context: context)
    }

    private static func makeExplicitModeResult(
        from selectedText: String,
        mode: ExecutionMode,
        context: TransformContext
    ) -> TransformResult? {
        let engine = TransformEngine()

        switch mode {
        case .automatic:
            return nil
        case .md5:
            return engine.transformMD5(input: selectedText, context: context)
        case .jsonCompress:
            guard let output = SecondaryActionPerformer.compressedJSON(from: selectedText) else {
                return TransformResult(
                    primaryOutput: nil,
                    secondaryActions: [],
                    displayMode: .error,
                    errorMessage: "JSON 校验失败。"
                )
            }
            return TransformResult(
                primaryOutput: output,
                secondaryActions: [.copyResult, .replaceSelection],
                displayMode: .code
            )
        }
    }

    private static func makePresentationTitle(for mode: ExecutionMode, selectedText: String) -> String {
        switch mode {
        case .automatic:
            let detector = ContentDetector()
            let detection = detector.detect(selectedText)
            return "自动识别 · \(automaticModeTitle(for: detection.kind))"
        case .md5:
            return "指定模式 · MD5"
        case .jsonCompress:
            return "指定模式 · JSON Compress"
        }
    }

    private static func makeErrorTitle(for mode: ExecutionMode) -> String {
        switch mode {
        case .automatic:
            return "自动识别 · 执行失败"
        default:
            return "指定模式 · 执行失败"
        }
    }

    private static func automaticModeTitle(for kind: ContentKind) -> String {
        switch kind {
        case .json:
            return "JSON"
        case .invalidJSON:
            return "JSON"
        case .timestamp:
            return "时间戳"
        case .dateString:
            return "日期"
        case .url:
            return "URL"
        case .plainText:
            return "文本"
        }
    }

    private static func reminderSummary(for selectedText: String) -> String {
        let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "将使用当前文本创建提醒事项。"
        }

        if let date = DateParsers.makeDate(from: trimmed) {
            let formattedDate = DateParsers.localDateTimeFormatter.string(from: date)
            return "将创建提醒事项：\(trimmed)\n提醒时间：\(formattedDate)"
        }

        return "将创建提醒事项：\(trimmed)"
    }

    private static func makeErrorResult(for failure: SelectionReadFailure) -> TransformResult {
        TransformResult(
            primaryOutput: nil,
            secondaryActions: [],
            displayMode: .error,
            errorMessage: message(for: failure)
        )
    }

    private static func makeTransformContext(
        for mode: ExecutionMode,
        selectedText: String
    ) -> TransformContext {
        switch mode {
        case .md5:
            return TransformContext(md5LetterCase: .lowercase)
        case .automatic, .jsonCompress:
            let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.allSatisfy(\.isNumber) {
                if trimmed.count == 10 {
                    return TransformContext(timestampPrecision: .seconds)
                }
                if trimmed.count == 13 {
                    return TransformContext(timestampPrecision: .milliseconds)
                }
            }
            return TransformContext()
        }
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
        openWorkspaceItem.target = NSApplication.shared.delegate
        appMenu.addItem(openWorkspaceItem)

        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(AppDelegate.openSettingsFromMainMenu(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = NSApplication.shared.delegate
        appMenu.addItem(settingsItem)

        let previewItem = NSMenuItem(
            title: "UI 预览...",
            action: #selector(AppDelegate.openUIPreviewFromMainMenu(_:)),
            keyEquivalent: "u"
        )
        previewItem.target = NSApplication.shared.delegate
        appMenu.addItem(previewItem)

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
        closeItem.target = NSApplication.shared.delegate
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
    private var uiPreviewWindowController: UIPreviewWindowController?
    private var permissionOnboardingWindowController: PermissionOnboardingWindowController?
    private var permissionOnboardingViewModel: PermissionOnboardingViewModel?
    private var toolWorkspaceWindow: NSWindow?
    private var popoverController: PopoverController?
    private var keyboardMonitor: KeyboardMonitor?
    private var currentExecutionMode: ExecutionMode = .defaultMode
    private var pendingRouteAfterPermissionOnboarding: PermissionOnboardingRoute?
    private let permissionStatusProvider: PermissionStatusProviding
    private let permissionPrompter: PermissionPrompting

    override init() {
        self.permissionStatusProvider = SystemPermissionStatusProvider()
        self.permissionPrompter = SystemPermissionPrompter()
        super.init()
    }

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
        statusBarController?.onExecutionModeChanged = { [weak self] mode in
            self?.currentExecutionMode = mode
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

        applyLaunchDecision()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        permissionOnboardingViewModel?.refreshStatuses()

        if makePermissionGate().isReadyForNormalUsage {
            startKeyboardMonitorIfNeeded()
            return
        }

        keyboardMonitor?.stop()
        showPermissionOnboarding()
    }

    @MainActor
    private func showSettings() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch self.makePermissionGate().routeForSettingsEntry() {
            case .settings:
                break
            case .permissionOnboarding:
                self.pendingRouteAfterPermissionOnboarding = .settings
                self.showPermissionOnboarding()
                return
            default:
                return
            }

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
    @objc func openUIPreviewFromMainMenu(_ sender: Any?) {
        showUIPreview()
    }

    @MainActor
    private func showToolWorkspace() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch self.makePermissionGate().routeForWorkspaceEntry() {
            case .workspace:
                break
            case .permissionOnboarding:
                self.pendingRouteAfterPermissionOnboarding = .workspace
                self.showPermissionOnboarding()
                return
            default:
                return
            }

            if self.toolWorkspaceWindow == nil {
                self.toolWorkspaceWindow = self.makeToolWorkspaceWindow()
            }
            self.toolWorkspaceWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @MainActor
    private func showUIPreview() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.uiPreviewWindowController == nil {
                self.uiPreviewWindowController = UIPreviewWindowController()
            }
            self.uiPreviewWindowController?.window?.level = .normal
            self.uiPreviewWindowController?.showWindow(nil)
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
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true
        window.toolbarStyle = .unifiedCompact
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.identifier = NSUserInterfaceItemIdentifier("toolWorkspaceWindow")
        return window
    }

    private func handleSpaceTrigger() {
        guard makePermissionGate().isReadyForNormalUsage else {
            showPermissionOnboarding()
            return
        }

        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: AccessibilityBridge.shared.readSelectedTextResult(),
            mode: currentExecutionMode
        )

        popoverController?.show(
            with: presentation.result,
            title: presentation.title,
            selectedText: presentation.selectedText,
            contentSource: presentation.contentSource,
            executionMode: currentExecutionMode,
            transformContext: presentation.transformContext,
            sourceMessage: presentation.sourceMessage,
            statusItemButton: statusBarController?.statusItemButton
        )
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
        } else if window.identifier == NSUserInterfaceItemIdentifier("uiPreviewWindow") {
            uiPreviewWindowController?.close()
        } else {
            window.close()
        }
    }

    private func applyLaunchDecision() {
        switch makePermissionGate().makeLaunchDecision().route {
        case .normalUsage:
            startKeyboardMonitorIfNeeded()
        case .permissionOnboarding:
            showPermissionOnboarding()
        default:
            break
        }
    }

    private func makePermissionGate() -> AppPermissionGate {
        AppPermissionGate(permissionStatusProvider: permissionStatusProvider)
    }

    private func startKeyboardMonitorIfNeeded() {
        keyboardMonitor?.start()
    }

    private func showPermissionOnboarding() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if self.permissionOnboardingViewModel == nil {
                let viewModel = PermissionOnboardingViewModel(
                    permissionStatusProvider: self.permissionStatusProvider,
                    permissionPrompter: self.permissionPrompter
                )
                viewModel.onContinueApproved = { [weak self] in
                    self?.handlePermissionOnboardingCompleted()
                }
                self.permissionOnboardingViewModel = viewModel
            }

            self.permissionOnboardingViewModel?.refreshStatuses()

            if self.permissionOnboardingWindowController == nil,
               let viewModel = self.permissionOnboardingViewModel {
                self.permissionOnboardingWindowController = PermissionOnboardingWindowController(
                    viewModel: viewModel
                )
                self.permissionOnboardingWindowController?.window?.delegate = self
            }

            self.permissionOnboardingWindowController?.showWindow(nil)
            self.permissionOnboardingWindowController?.window?.level = .normal
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @MainActor
    private func handlePermissionOnboardingCompleted() {
        permissionOnboardingWindowController?.close()
        startKeyboardMonitorIfNeeded()

        let pendingRoute = pendingRouteAfterPermissionOnboarding
        pendingRouteAfterPermissionOnboarding = nil

        switch pendingRoute {
        case .settings:
            showSettings()
        case .workspace:
            showToolWorkspace()
        default:
            break
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard sender.identifier == NSUserInterfaceItemIdentifier("permissionOnboardingWindow") else {
            return true
        }

        if makePermissionGate().isReadyForNormalUsage {
            return true
        }

        permissionOnboardingViewModel?.refreshStatuses()
        showPermissionOnboarding()
        return false
    }
}
