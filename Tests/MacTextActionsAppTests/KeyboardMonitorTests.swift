import XCTest
import CoreGraphics
@testable import MacTextActionsApp

final class KeyboardMonitorTests: XCTestCase {
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
