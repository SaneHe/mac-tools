import XCTest
@testable import MacTextActionsApp

final class PanelContentFactoryTests: XCTestCase {
    func testJsonToolUsesChinesePresentationCopy() {
        XCTAssertEqual(ToolType.json.rawValue, "JSON 格式化")
        XCTAssertEqual(ToolType.json.summary, "格式化与校验结构化文本")
        XCTAssertEqual(ToolType.json.placeholder, "粘贴 JSON 文本")
    }

    func testCompactToolsUseUnifiedPlaceholderCopyAndHeights() {
        XCTAssertEqual(ToolType.timestamp.placeholder, "输入时间戳或日期")
        XCTAssertEqual(ToolType.md5.placeholder, "输入任意文本")
        XCTAssertEqual(ToolType.url.placeholder, "输入 URL 或文本")

        XCTAssertEqual(ToolType.timestamp.inputHeight, 60)
        XCTAssertEqual(ToolType.md5.inputHeight, 120)
        XCTAssertEqual(ToolType.url.inputHeight, 120)

        XCTAssertEqual(ToolType.timestamp.resultHeight, 80)
        XCTAssertEqual(ToolType.md5.resultHeight, 120)
        XCTAssertEqual(ToolType.url.resultHeight, 120)
    }
}
