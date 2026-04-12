import XCTest
import CoreGraphics
@testable import MacTextActionsApp

final class KeyboardMonitorTests: XCTestCase {
    func testEnsureActiveRebuildsEventTapWhenControllerIsDisabled() {
        let tapController = KeyboardEventTapControllerSpy()
        let monitor = KeyboardMonitor(
            configuration: .default,
            permissionStatusProvider: KeyboardPermissionStatusProviderStub(),
            permissionPrompter: KeyboardPermissionPrompterSpy(),
            eventTapController: tapController
        )

        monitor.start()
        tapController.isEnabled = false

        monitor.ensureActive()

        XCTAssertEqual(tapController.installCallCount, 2)
        XCTAssertEqual(tapController.uninstallCallCount, 1)
    }

    func testEnsureActiveDoesNotRebuildEventTapWhenControllerIsHealthy() {
        let tapController = KeyboardEventTapControllerSpy()
        let monitor = KeyboardMonitor(
            configuration: .default,
            permissionStatusProvider: KeyboardPermissionStatusProviderStub(),
            permissionPrompter: KeyboardPermissionPrompterSpy(),
            eventTapController: tapController
        )

        monitor.start()
        monitor.ensureActive()

        XCTAssertEqual(tapController.installCallCount, 1)
        XCTAssertEqual(tapController.uninstallCallCount, 0)
    }

    func testRecoverableEventRebuildsEventTapThroughSharedRecoveryPath() {
        let tapController = KeyboardEventTapControllerSpy()
        let monitor = KeyboardMonitor(
            configuration: .default,
            permissionStatusProvider: KeyboardPermissionStatusProviderStub(),
            permissionPrompter: KeyboardPermissionPrompterSpy(),
            eventTapController: tapController
        )

        monitor.start()
        monitor.processSystemEvent(type: .tapDisabledByTimeout)

        XCTAssertEqual(tapController.installCallCount, 2)
        XCTAssertEqual(tapController.uninstallCallCount, 1)
    }

    func testTapDisabledByTimeoutRequiresRecovery() {
        XCTAssertTrue(
            KeyboardMonitor.shouldRecover(
                for: .tapDisabledByTimeout
            )
        )
    }

    func testRegularKeyDownDoesNotRequireRecovery() {
        XCTAssertFalse(
            KeyboardMonitor.shouldRecover(
                for: .keyDown
            )
        )
    }

    func testGlobalShortcutTriggersForOptionSpace() {
        let config = ShortcutConfiguration(keyCode: 49, modifiers: [.option])
        let shouldTrigger = KeyboardMonitor.shouldTriggerShortcut(
            keyCode: KeyboardMonitor.KeyCode.space,
            flags: .maskAlternate,
            isRepeat: false,
            configuration: config
        )

        XCTAssertTrue(shouldTrigger)
    }

    func testGlobalShortcutIgnoresRepeatedOptionSpace() {
        let config = ShortcutConfiguration(keyCode: 49, modifiers: [.option])
        let shouldTrigger = KeyboardMonitor.shouldTriggerShortcut(
            keyCode: KeyboardMonitor.KeyCode.space,
            flags: .maskAlternate,
            isRepeat: true,
            configuration: config
        )

        XCTAssertFalse(shouldTrigger)
    }

    func testGlobalShortcutIgnoresSpaceWithoutOption() {
        let config = ShortcutConfiguration(keyCode: 49, modifiers: [.option])
        let shouldTrigger = KeyboardMonitor.shouldTriggerShortcut(
            keyCode: KeyboardMonitor.KeyCode.space,
            flags: [],
            isRepeat: false,
            configuration: config
        )

        XCTAssertFalse(shouldTrigger)
    }

    func testGlobalShortcutIgnoresCommandSpace() {
        let config = ShortcutConfiguration(keyCode: 49, modifiers: [.option])
        let shouldTrigger = KeyboardMonitor.shouldTriggerShortcut(
            keyCode: KeyboardMonitor.KeyCode.space,
            flags: .maskCommand,
            isRepeat: false,
            configuration: config
        )

        XCTAssertFalse(shouldTrigger)
    }

    func testGlobalShortcutIgnoresOtherKeysWithOption() {
        let config = ShortcutConfiguration(keyCode: 49, modifiers: [.option])
        let shouldTrigger = KeyboardMonitor.shouldTriggerShortcut(
            keyCode: 1, // 其他键
            flags: .maskAlternate,
            isRepeat: false,
            configuration: config
        )

        XCTAssertFalse(shouldTrigger)
    }

    func testGlobalShortcutTriggersForCtrlSpace() {
        let config = ShortcutConfiguration(keyCode: 49, modifiers: [.control])
        let shouldTrigger = KeyboardMonitor.shouldTriggerShortcut(
            keyCode: KeyboardMonitor.KeyCode.space,
            flags: .maskControl,
            isRepeat: false,
            configuration: config
        )

        XCTAssertTrue(shouldTrigger)
    }

    func testGlobalShortcutTriggersForCmdShiftSpace() {
        let config = ShortcutConfiguration(keyCode: 49, modifiers: [.command, .shift])
        let shouldTrigger = KeyboardMonitor.shouldTriggerShortcut(
            keyCode: KeyboardMonitor.KeyCode.space,
            flags: [.maskCommand, .maskShift],
            isRepeat: false,
            configuration: config
        )

        XCTAssertTrue(shouldTrigger)
    }
}

private struct KeyboardPermissionStatusProviderStub: PermissionStatusProviding {
    func isAccessibilityAuthorized() -> Bool {
        true
    }

    func isInputMonitoringAuthorized() -> Bool {
        true
    }
}

private final class KeyboardPermissionPrompterSpy: PermissionPrompting {
    func requestAccessibilityPermission() {}
    func requestInputMonitoringPermission() {}
}

private final class KeyboardEventTapControllerSpy: KeyboardEventTapControlling {
    private(set) var installCallCount = 0
    private(set) var uninstallCallCount = 0
    var isInstalled = false
    var isEnabled = false

    func install(
        handler: @escaping (CGEventType, CGEvent) -> Void
    ) -> Bool {
        installCallCount += 1
        isInstalled = true
        isEnabled = true
        return true
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    func uninstall() {
        if isInstalled {
            uninstallCallCount += 1
        }
        isInstalled = false
        isEnabled = false
    }
}
