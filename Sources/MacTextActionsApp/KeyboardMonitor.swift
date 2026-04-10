import AppKit
import Carbon.HIToolbox
import CoreGraphics

final class KeyboardMonitor {
    enum KeyCode {
        static let space: Int64 = 49
    }

    var onShortcutTriggered: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let permissionStatusProvider: PermissionStatusProviding
    private let permissionPrompter: PermissionPrompting
    private var currentConfiguration: ShortcutConfiguration

    init(
        configuration: ShortcutConfiguration = ShortcutSettingsManager.shared.configuration,
        permissionStatusProvider: PermissionStatusProviding = SystemPermissionStatusProvider(),
        permissionPrompter: PermissionPrompting = SystemPermissionPrompter()
    ) {
        self.currentConfiguration = configuration
        self.permissionStatusProvider = permissionStatusProvider
        self.permissionPrompter = permissionPrompter

        // 监听配置变化
        ShortcutSettingsManager.shared.onConfigurationChanged = { [weak self] newConfig in
            self?.updateConfiguration(newConfig)
        }
    }

    func updateConfiguration(_ configuration: ShortcutConfiguration) {
        currentConfiguration = configuration
        // 如果正在监听，需要重启以应用新配置
        if eventTap != nil {
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

        let eventMask = (1 << CGEventType.keyDown.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.handleEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap = eventTap else {
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        if Self.shouldRecover(for: type) {
            recoverEventTap()
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

    private func recoverEventTap() {
        guard let eventTap else {
            start()
            return
        }

        CGEvent.tapEnable(tap: eventTap, enable: true)
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
