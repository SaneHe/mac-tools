import XCTest
@testable import MacTextActionsApp

final class PanelContentFactoryTests: XCTestCase {
    func testPlainTextStateUsesChinesePresentationCopy() {
        let factory = PanelContentFactory()

        let state = factory.makeState(from: "hello")

        guard case let .content(content) = state else {
            return XCTFail("Expected content state")
        }

        XCTAssertEqual(content.title, "普通文本")
        XCTAssertEqual(content.subtitle, "选中文本预览")
        XCTAssertEqual(content.footerNote, "MD5 和提醒创建需要手动触发。")
    }
}
