import XCTest
import AppKit
@testable import MacTextActionsApp

final class ShortcutRecorderLogicTests: XCTestCase {
    func testRecorderIgnoresModifierOnlyKeyPress() {
        let result = ShortcutRecorderLogic.capture(
            keyCode: 56,
            modifierFlags: [.shift]
        )

        XCTAssertNil(result)
    }

    func testRecorderBuildsConfigurationForValidShortcut() {
        let result = ShortcutRecorderLogic.capture(
            keyCode: ShortcutConfiguration.KeyCode.space,
            modifierFlags: [.option, .shift]
        )

        XCTAssertEqual(
            result,
            ShortcutConfiguration(
                keyCode: ShortcutConfiguration.KeyCode.space,
                modifiers: [.option, .shift]
            )
        )
    }

    func testRecorderRejectsFunctionModifierShortcut() {
        let result = ShortcutRecorderLogic.capture(
            keyCode: ShortcutConfiguration.KeyCode.space,
            modifierFlags: [.function, .command]
        )

        XCTAssertNil(result)
    }

    func testRecorderTreatsEscapeAsCancel() {
        XCTAssertEqual(
            ShortcutRecorderLogic.interpretControlKey(keyCode: 53),
            .cancel
        )
    }
}
