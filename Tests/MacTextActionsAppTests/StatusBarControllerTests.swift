import XCTest
import AppKit
@testable import MacTextActionsApp

@MainActor
final class StatusBarControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testClosingMenuAfterModeSwitchReactivatesPreviousFrontmostApplication() throws {
        let previousApp = TestRunningApplication()
        let frontmostManager = TestFrontmostApplicationManager(frontmostApplication: previousApp)
        let controller = StatusBarController(frontmostApplicationManager: frontmostManager)
        let menu = try XCTUnwrap(controller.menuItems.first?.menu)
        let md5Item = try XCTUnwrap(controller.menuItems.first { $0.title == "MD5" })

        controller.menuWillOpen(menu)
        _ = md5Item.target?.perform(md5Item.action, with: md5Item)
        controller.menuDidClose(menu)

        XCTAssertEqual(frontmostManager.activateCallCount, 1)
        XCTAssertTrue(frontmostManager.lastActivatedApplication === previousApp)
    }

    func testClosingMenuWithoutModeSwitchDoesNotReactivatePreviousApplication() throws {
        let previousApp = TestRunningApplication()
        let frontmostManager = TestFrontmostApplicationManager(frontmostApplication: previousApp)
        let controller = StatusBarController(frontmostApplicationManager: frontmostManager)
        let menu = try XCTUnwrap(controller.menuItems.first?.menu)

        controller.menuWillOpen(menu)
        controller.menuDidClose(menu)

        XCTAssertEqual(frontmostManager.activateCallCount, 0)
    }

    func testStatusBarMenuContainsAllExecutionModes() {
        let controller = StatusBarController()

        let titles = controller.menuItems.map(\.title)

        XCTAssertEqual(
            Array(titles.prefix(3)),
            [
                "自动识别",
                "MD5",
                "JSON Compress"
            ]
        )
        XCTAssertFalse(titles.contains("创建提醒事项"))
        XCTAssertFalse(titles.contains("JSON 格式化"))
        XCTAssertFalse(titles.contains("时间戳转本地时间"))
        XCTAssertFalse(titles.contains("日期转时间戳"))
    }

    func testAutomaticExecutionModeIsCheckedByDefault() {
        let controller = StatusBarController()

        let automaticItem = controller.menuItems.first { $0.title == "自动识别" }

        XCTAssertEqual(automaticItem?.state, .on)
    }

    func testExecutionModeItemsUseCommandNumberShortcuts() throws {
        let controller = StatusBarController()
        let expectedShortcuts: [String: String] = [
            "自动识别": "1",
            "MD5": "2",
            "JSON Compress": "3",
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

        XCTAssertEqual(actionItems.count, 6)
        XCTAssertTrue(actionItems.allSatisfy { $0.target === controller })
    }

    func testStatusBarMenuContainsWorkspaceSettingsAndQuitEntries() {
        let controller = StatusBarController()
        let titles = controller.menuItems.map(\.title)

        XCTAssertTrue(titles.contains("打开工具"))
        XCTAssertTrue(titles.contains("设置..."))
        XCTAssertTrue(titles.contains("退出"))
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

private final class TestFrontmostApplicationManager: FrontmostApplicationManaging {
    var frontmostApplication: RunningApplicationActivating?
    private(set) var activateCallCount = 0
    private(set) weak var lastActivatedApplication: RunningApplicationActivating?

    init(frontmostApplication: RunningApplicationActivating?) {
        self.frontmostApplication = frontmostApplication
    }

    func currentFrontmostApplication() -> RunningApplicationActivating? {
        frontmostApplication
    }

    func activate(_ application: RunningApplicationActivating) {
        activateCallCount += 1
        lastActivatedApplication = application
        application.activate(options: [])
    }
}

private final class TestRunningApplication: RunningApplicationActivating {
    private(set) var activationCount = 0

    func activate(options: NSApplication.ActivationOptions) -> Bool {
        activationCount += 1
        return true
    }
}
