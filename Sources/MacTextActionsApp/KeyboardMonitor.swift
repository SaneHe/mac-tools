import AppKit
import Carbon.HIToolbox
import CoreGraphics
import OSLog

protocol KeyboardEventTapControlling: AnyObject {
    var isInstalled: Bool { get }
    var isEnabled: Bool { get }

    func install(handler: @escaping (CGEventType, CGEvent) -> Void) -> Bool
    func setEnabled(_ enabled: Bool)
    func uninstall()
}

final class SystemKeyboardEventTapController: KeyboardEventTapControlling {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var handler: ((CGEventType, CGEvent) -> Void)?

    var isInstalled: Bool {
        eventTap != nil && runLoopSource != nil
    }

    var isEnabled: Bool {
        guard let eventTap else {
            return false
        }

        return CFMachPortIsValid(eventTap) && CGEvent.tapIsEnabled(tap: eventTap)
    }

    func install(handler: @escaping (CGEventType, CGEvent) -> Void) -> Bool {
        uninstall()
        self.handler = handler

        let eventMask = (1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else {
                return Unmanaged.passUnretained(event)
            }

            let controller = Unmanaged<SystemKeyboardEventTapController>
                .fromOpaque(refcon)
                .takeUnretainedValue()
            controller.handler?(type, event)
            return Unmanaged.passUnretained(event)
        }

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap else {
            self.handler = nil
            return false
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        guard let runLoopSource else {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
            self.handler = nil
            return false
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return true
    }

    func setEnabled(_ enabled: Bool) {
        guard let eventTap else {
            return
        }

        CGEvent.tapEnable(tap: eventTap, enable: enabled)
    }

    func uninstall() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        handler = nil
        eventTap = nil
        runLoopSource = nil
    }

    deinit {
        uninstall()
    }
}

final class KeyboardMonitor {
    enum KeyCode {
        static let space: Int64 = 49
    }

    var onShortcutTriggered: (() -> Void)?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MacTextActionsApp",
        category: "ShortcutMonitor"
    )
    private let permissionStatusProvider: PermissionStatusProviding
    private let permissionPrompter: PermissionPrompting
    private let eventTapController: KeyboardEventTapControlling
    private var currentConfiguration: ShortcutConfiguration
    private var isMonitoring = false

    init(
        configuration: ShortcutConfiguration = ShortcutSettingsManager.shared.configuration,
        permissionStatusProvider: PermissionStatusProviding = SystemPermissionStatusProvider(),
        permissionPrompter: PermissionPrompting = SystemPermissionPrompter(),
        eventTapController: KeyboardEventTapControlling = SystemKeyboardEventTapController()
    ) {
        self.currentConfiguration = configuration
        self.permissionStatusProvider = permissionStatusProvider
        self.permissionPrompter = permissionPrompter
        self.eventTapController = eventTapController

        // 监听配置变化
        ShortcutSettingsManager.shared.onConfigurationChanged = { [weak self] newConfig in
            self?.updateConfiguration(newConfig)
        }
    }

    func updateConfiguration(_ configuration: ShortcutConfiguration) {
        currentConfiguration = configuration
        // 如果正在监听，需要重启以应用新配置
        if isMonitoring {
            stop()
            start()
        }
    }

    func start() {
        stop()

        guard permissionStatusProvider.isInputMonitoringAuthorized() else {
            permissionPrompter.requestInputMonitoringPermission()
            return
        }

        guard installEventTap() else {
            logger.error("无法创建全局快捷键监听 event tap")
            return
        }
        isMonitoring = true
    }

    func stop() {
        isMonitoring = false
        eventTapController.uninstall()
    }

    func ensureActive() {
        guard permissionStatusProvider.isInputMonitoringAuthorized() else {
            logger.info("输入监听权限不可用，停止快捷键监听")
            stop()
            return
        }

        guard isMonitoring else {
            start()
            return
        }

        guard eventTapController.isInstalled, eventTapController.isEnabled else {
            recoverEventTap(reason: "ensureActive")
            return
        }
    }

    func processSystemEvent(type: CGEventType) {
        guard Self.shouldRecover(for: type) else {
            return
        }

        recoverEventTap(reason: "systemDisabled")
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        if Self.shouldRecover(for: type) {
            processSystemEvent(type: type)
            return
        }

        guard type == .keyDown else {
            return
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        let flags = event.flags

        if shouldTriggerShortcut(keyCode: keyCode, flags: flags, isRepeat: isRepeat) {
            DispatchQueue.main.async { [weak self] in
                self?.onShortcutTriggered?()
            }
        }
    }

    private func installEventTap() -> Bool {
        eventTapController.install { [weak self] type, event in
            self?.handleEvent(type: type, event: event)
        }
    }

    private func recoverEventTap(reason: StaticString) {
        logger.info("正在恢复全局快捷键监听: \(reason)")

        guard isMonitoring else {
            start()
            return
        }

        eventTapController.uninstall()

        guard installEventTap() else {
            logger.error("恢复全局快捷键监听失败")
            isMonitoring = false
            return
        }

        eventTapController.setEnabled(true)
    }

    /// 检查是否应该触发的静态方法，用于测试
    static func shouldTriggerShortcut(
        keyCode: Int64,
        flags: CGEventFlags,
        isRepeat: Bool,
        configuration: ShortcutConfiguration
    ) -> Bool {
        // 检查按键码
        guard keyCode == configuration.keyCode else {
            return false
        }

        // 忽略重复按键
        guard !isRepeat else {
            return false
        }

        // 获取事件中的修饰键状态
        let hasCommand = flags.contains(.maskCommand)
        let hasOption = flags.contains(.maskAlternate)
        let hasControl = flags.contains(.maskControl)
        let hasShift = flags.contains(.maskShift)
        let hasFunction = flags.contains(.maskSecondaryFn)

        // 获取配置要求的修饰键
        let needsCommand = configuration.modifiers.contains(.command)
        let needsOption = configuration.modifiers.contains(.option)
        let needsControl = configuration.modifiers.contains(.control)
        let needsShift = configuration.modifiers.contains(.shift)
        let needsFunction = configuration.modifiers.contains(.function)

        // 检查是否所有必需的修饰键都已按下
        if needsCommand && !hasCommand { return false }
        if needsOption && !hasOption { return false }
        if needsControl && !hasControl { return false }
        if needsShift && !hasShift { return false }
        if needsFunction && !hasFunction { return false }

        // 检查是否没有多余的修饰键
        if hasCommand && !needsCommand { return false }
        if hasOption && !needsOption { return false }
        if hasControl && !needsControl { return false }
        if hasShift && !needsShift { return false }
        if hasFunction && !needsFunction { return false }

        return true
    }

    static func shouldRecover(for eventType: CGEventType) -> Bool {
        eventType == .tapDisabledByTimeout || eventType == .tapDisabledByUserInput
    }

    /// 实例方法版本，使用当前配置
    private func shouldTriggerShortcut(
        keyCode: Int64,
        flags: CGEventFlags,
        isRepeat: Bool
    ) -> Bool {
        return Self.shouldTriggerShortcut(
            keyCode: keyCode,
            flags: flags,
            isRepeat: isRepeat,
            configuration: currentConfiguration
        )
    }

    deinit {
        stop()
    }
}
