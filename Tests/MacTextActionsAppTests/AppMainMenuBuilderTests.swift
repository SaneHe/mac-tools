import AppKit
import XCTest
@testable import MacTextActionsApp

@MainActor
final class AppMainMenuBuilderTests: XCTestCase {
    func testApplicationMenuIncludesUIPreviewEntry() throws {
        let mainMenu = AppMainMenuBuilder.build(appName: "Mac Text Actions")
        let applicationMenu = try XCTUnwrap(mainMenu.items.first?.submenu)
        let menuTitles = applicationMenu.items.map(\.title)

        XCTAssertTrue(menuTitles.contains("UI 预览..."))
    }
}
