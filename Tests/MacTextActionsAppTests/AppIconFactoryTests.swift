import XCTest
import AppKit
@testable import MacTextActionsApp

final class AppIconFactoryTests: XCTestCase {
    func testApplicationIconUsesRequestedSize() {
        let icon = AppIconFactory.makeApplicationIcon(size: 256)

        XCTAssertEqual(icon.size.width, 256)
        XCTAssertEqual(icon.size.height, 256)
    }

    func testStatusBarIconUsesTemplateRendering() {
        let icon = AppIconFactory.makeStatusBarIcon(size: 18)

        XCTAssertTrue(icon.isTemplate)
    }
}
