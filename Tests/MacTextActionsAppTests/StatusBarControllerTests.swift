import XCTest
import AppKit
@testable import MacTextActionsApp

@MainActor
final class StatusBarControllerTests: XCTestCase {
    func testActionMenuItemsBindExplicitTargetToController() {
        let controller = StatusBarController()

        let actionItems = controller.menuItems.filter { $0.action != nil }

        XCTAssertEqual(actionItems.count, 3)
        XCTAssertTrue(actionItems.allSatisfy { $0.target === controller })
    }

    func testAppMainMenuContainsStandardEditCommands() {
        let mainMenu = AppMainMenuBuilder.build(appName: "Mac Text Actions")

        let topLevelTitles = mainMenu.items.compactMap(\.title)
        XCTAssertTrue(topLevelTitles.contains("编辑"))

        let editMenu = mainMenu.items.first { $0.title == "编辑" }?.submenu
        let editActions = editMenu?.items.compactMap(\.action) ?? []

        XCTAssertTrue(editActions.contains(#selector(NSText.cut(_:))))
        XCTAssertTrue(editActions.contains(#selector(NSText.copy(_:))))
        XCTAssertTrue(editActions.contains(#selector(NSText.paste(_:))))
        XCTAssertTrue(editActions.contains(#selector(NSText.selectAll(_:))))
    }

    func testAppMainMenuContainsWorkspaceAndSettingsEntries() {
        let mainMenu = AppMainMenuBuilder.build(appName: "Mac Text Actions")
        let appMenu = mainMenu.items.first?.submenu
        let titles = appMenu?.items.map(\.title) ?? []

        XCTAssertTrue(titles.contains("打开工具"))
        XCTAssertTrue(titles.contains("设置..."))
    }
}
