import AppKit
import XCTest
@testable import MacTextActionsApp

@MainActor
final class ExecutionModeShortcutTests: XCTestCase {
    func testExecutionModeShortcutsFollowMenuOrder() {
        XCTAssertEqual(
            ExecutionMode.allCases.map(\.keyEquivalent),
            ["1", "2", "3"]
        )
    }

    func testExecutionModeShortcutSummaryMatchesSequentialMenuOrder() {
        XCTAssertEqual(
            ExecutionMode.shortcutSummaryText,
            "⌘1 自动识别 / ⌘2 MD5 / ⌘3 JSON Compress（菜单展开时切换模式）"
        )
    }

    func testRefreshingMenuStateOnlyChecksExecutionModeItems() {
        let automaticItem = NSMenuItem(title: "自动识别", action: nil, keyEquivalent: "")
        automaticItem.tag = StatusBarMenuState.tag(for: .automatic)

        let md5Item = NSMenuItem(title: "MD5", action: nil, keyEquivalent: "")
        md5Item.tag = StatusBarMenuState.tag(for: .md5)

        let openWorkspaceItem = NSMenuItem(title: "打开工具", action: nil, keyEquivalent: "")
        let settingsItem = NSMenuItem(title: "设置...", action: nil, keyEquivalent: "")
        let quitItem = NSMenuItem(title: "退出", action: nil, keyEquivalent: "")

        StatusBarMenuState.refresh(
            [automaticItem, md5Item, openWorkspaceItem, settingsItem, quitItem],
            currentExecutionMode: .automatic
        )

        XCTAssertEqual(automaticItem.state, .on)
        XCTAssertEqual(md5Item.state, .off)
        XCTAssertEqual(openWorkspaceItem.state, .off)
        XCTAssertEqual(settingsItem.state, .off)
        XCTAssertEqual(quitItem.state, .off)
    }

    func testDefaultMenuItemTagDoesNotResolveToExecutionMode() {
        let actionItem = NSMenuItem(title: "打开工具", action: nil, keyEquivalent: "")

        XCTAssertNil(StatusBarMenuState.executionMode(for: actionItem))
    }
}
