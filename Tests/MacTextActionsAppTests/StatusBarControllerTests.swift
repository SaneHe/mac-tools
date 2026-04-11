import XCTest
import AppKit
@testable import MacTextActionsApp

@MainActor
final class StatusBarControllerTests: XCTestCase {
    func testStatusBarMenuContainsAllExecutionModes() {
        let controller = StatusBarController()

        let titles = controller.menuItems.map(\.title)

        XCTAssertTrue(titles.contains("自动识别"))
        XCTAssertTrue(titles.contains("JSON 格式化"))
        XCTAssertTrue(titles.contains("JSON Compress"))
        XCTAssertTrue(titles.contains("时间戳转本地时间"))
        XCTAssertTrue(titles.contains("日期转时间戳"))
        XCTAssertTrue(titles.contains("MD5"))
        XCTAssertTrue(titles.contains("创建提醒事项"))
    }

    func testAutomaticExecutionModeIsCheckedByDefault() {
        let controller = StatusBarController()

        let automaticItem = controller.menuItems.first { $0.title == "自动识别" }

        XCTAssertEqual(automaticItem?.state, .on)
    }

    func testExecutionModeItemsUseCommandNumberShortcuts() throws {
        let controller = StatusBarController()
        let expectedShortcuts: [String: String] = [
            "自动识别": "0",
            "JSON 格式化": "1",
            "JSON Compress": "2",
            "时间戳转本地时间": "3",
            "日期转时间戳": "4",
            "MD5": "5",
            "创建提醒事项": "6"
        ]

        for (title, keyEquivalent) in expectedShortcuts {
            let item = try XCTUnwrap(controller.menuItems.first { $0.title == title })
            XCTAssertEqual(item.keyEquivalent, keyEquivalent)
            XCTAssertEqual(item.keyEquivalentModifierMask, [.command])
        }
    }

    func testSelectingExecutionModeUpdatesCheckedState() throws {
        let controller = StatusBarController()
        let jsonCompressItem = try XCTUnwrap(controller.menuItems.first { $0.title == "JSON Compress" })

        _ = jsonCompressItem.target?.perform(jsonCompressItem.action, with: jsonCompressItem)

        let automaticItem = controller.menuItems.first { $0.title == "自动识别" }

        XCTAssertEqual(jsonCompressItem.state, .on)
        XCTAssertEqual(automaticItem?.state, .off)
    }

    func testActionMenuItemsBindExplicitTargetToController() {
        let controller = StatusBarController()

        let actionItems = controller.menuItems.filter { $0.action != nil }

        XCTAssertEqual(actionItems.count, 9)
        XCTAssertTrue(actionItems.allSatisfy { $0.target === controller })
    }

    func testAppMainMenuContainsStandardEditCommands() {
        let mainMenu = AppMainMenuBuilder.build(appName: "Mac Text Actions")

        let topLevelTitles = mainMenu.items.map(\.title)
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
