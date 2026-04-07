import XCTest
import MacTextActionsCore
@testable import MacTextActionsApp

final class SelectionTriggerPresentationFactoryTests: XCTestCase {
    func testBuildsErrorPanelWhenNoSelectionIsAvailable() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .failure(.noSelection)
        )

        XCTAssertEqual(presentation.selectedText, "")
        XCTAssertEqual(presentation.contentSource, .selection)
        XCTAssertEqual(presentation.result.displayMode, .error)
        XCTAssertEqual(presentation.result.errorMessage, "未检测到可处理文本")
        XCTAssertTrue(presentation.result.secondaryActions.isEmpty)
    }

    func testBuildsErrorPanelWhenApplicationDoesNotExposeSelection() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .failure(.unsupportedApplication)
        )

        XCTAssertEqual(presentation.selectedText, "")
        XCTAssertEqual(presentation.contentSource, .selection)
        XCTAssertEqual(presentation.result.displayMode, .error)
        XCTAssertEqual(presentation.result.errorMessage, "当前应用暂不支持读取选中文本")
        XCTAssertTrue(presentation.result.secondaryActions.isEmpty)
    }

    func testBuildsErrorPanelWhenAccessibilityPermissionIsMissing() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .failure(.permissionDenied)
        )

        XCTAssertEqual(presentation.selectedText, "")
        XCTAssertEqual(presentation.contentSource, .selection)
        XCTAssertEqual(presentation.result.displayMode, .error)
        XCTAssertEqual(presentation.result.errorMessage, "请先在系统设置中开启辅助功能权限")
        XCTAssertTrue(presentation.result.secondaryActions.isEmpty)
    }

    func testBuildsTransformResultForSuccessfulSelection() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .success("{\"name\":\"codex\"}")
        )

        XCTAssertEqual(presentation.selectedText, "{\"name\":\"codex\"}")
        XCTAssertEqual(presentation.contentSource, .selection)
        XCTAssertEqual(presentation.result.displayMode, .code)
        XCTAssertEqual(presentation.result.primaryOutput, "{\n  \"name\" : \"codex\"\n}")
        XCTAssertEqual(
            presentation.result.secondaryActions,
            [.copyResult, .replaceSelection, .compressJSON]
        )
    }

    func testBuildsTransformResultWhenClipboardFallbackProvidesText() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .fallbackSuccess(
                text: "{\"name\":\"clipboard\"}",
                failure: .noSelection
            )
        )

        XCTAssertEqual(presentation.selectedText, "{\"name\":\"clipboard\"}")
        XCTAssertEqual(presentation.contentSource, .clipboardFallback)
        XCTAssertEqual(presentation.result.displayMode, .code)
        XCTAssertEqual(presentation.result.primaryOutput, "{\n  \"name\" : \"clipboard\"\n}")
    }

    func testBuildsFallbackNoticeWhenClipboardFallbackReplacesUnsupportedSelection() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .fallbackSuccess(
                text: "1712205045",
                failure: .unsupportedApplication
            )
        )

        XCTAssertEqual(presentation.selectedText, "1712205045")
        XCTAssertEqual(presentation.contentSource, .clipboardFallback)
        XCTAssertEqual(presentation.sourceMessage, "已改用剪贴板内容")
    }
}
