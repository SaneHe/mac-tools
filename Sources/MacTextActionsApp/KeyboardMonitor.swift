import Foundation
import HotKey
import OSLog

protocol HotKeyControlling: AnyObject {
    var isRegistered: Bool { get }
    var isPaused: Bool { get }

    func register(
        configuration: ShortcutConfiguration,
        handler: @escaping () -> Void
    )
    func unregister()
}

final class SystemHotKeyController: HotKeyControlling {
    private var hotKey: HotKey?

    var isRegistered: Bool {
        hotKey != nil
    }

    var isPaused: Bool {
        hotKey?.isPaused ?? true
    }

    func register(
        configuration: ShortcutConfiguration,
        handler: @escaping () -> Void
    ) {
        unregister()

        guard configuration.isSupportedByHotKey else {
            return
        }

        let keyCombo = KeyCombo(
            carbonKeyCode: UInt32(configuration.keyCode),
            carbonModifiers: configuration.modifiers.carbonFlags
        )
        let hotKey = HotKey(keyCombo: keyCombo)
        hotKey.keyDownHandler = handler
        hotKey.isPaused = false
        self.hotKey = hotKey
    }

    func unregister() {
        hotKey?.isPaused = true
        hotKey = nil
    }
}

final class KeyboardMonitor {
    var onShortcutTriggered: (() -> Void)?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MacTextActionsApp",
        category: "ShortcutMonitor"
    )
    private let hotKeyController: HotKeyControlling
    private var currentConfiguration: ShortcutConfiguration
    private var isMonitoring = false

    init(
        configuration: ShortcutConfiguration = ShortcutSettingsManager.shared.configuration,
        hotKeyController: HotKeyControlling = SystemHotKeyController()
    ) {
        self.currentConfiguration = configuration
        self.hotKeyController = hotKeyController

        ShortcutSettingsManager.shared.onConfigurationChanged = { [weak self] newConfig in
            self?.updateConfiguration(newConfig)
        }
    }

    func updateConfiguration(_ configuration: ShortcutConfiguration) {
        currentConfiguration = configuration

        if isMonitoring {
            start()
        }
    }

    func start() {
        stop()

        guard currentConfiguration.isSupportedByHotKey else {
            logger.error("当前快捷键不受 HotKey 支持: \(self.currentConfiguration.displayString, privacy: .public)")
            return
        }


        hotKeyController.register(configuration: currentConfiguration) { [weak self] in
            DispatchQueue.main.async {
                self?.onShortcutTriggered?()
            }
        }
        isMonitoring = hotKeyController.isRegistered
    }

    func stop() {
        isMonitoring = false
        hotKeyController.unregister()
    }

    func ensureActive() {
        guard isMonitoring else {
            start()
            return
        }

        guard hotKeyController.isRegistered, !hotKeyController.isPaused else {
            logger.info("正在重新注册全局快捷键")
            start()
            return
        }
    }

    deinit {
        stop()
    }
}
