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
}
