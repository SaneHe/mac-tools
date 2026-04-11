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

        XCTAssertEqual(presentation.title, "自动识别 · JSON")
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

        XCTAssertEqual(presentation.title, "自动识别 · JSON")
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
        XCTAssertEqual(presentation.sourceMessage, "已改用剪贴板内容，不是当前实时选区")
    }

    func testBuildsExplicitJsonCompressPresentation() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .success("{\"name\":\"codex\",\"enabled\":true}"),
            mode: .jsonCompress
        )

        XCTAssertEqual(presentation.title, "指定模式 · JSON Compress")
        XCTAssertEqual(presentation.result.displayMode, .code)
        XCTAssertEqual(presentation.result.primaryOutput, "{\"enabled\":true,\"name\":\"codex\"}")
    }

    func testBuildsExplicitMD5Presentation() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .success("hello"),
            mode: .md5
        )

        XCTAssertEqual(presentation.title, "指定模式 · MD5")
        XCTAssertEqual(presentation.result.displayMode, .text)
        XCTAssertEqual(presentation.result.primaryOutput, "5d41402abc4b2a76b9719d911017c592")
    }

    func testBuildsExplicitDateToTimestampPresentation() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .success("2024-03-08T12:34:56Z"),
            mode: .dateToTimestamp
        )

        XCTAssertEqual(presentation.title, "指定模式 · 日期转时间戳")
        XCTAssertEqual(presentation.result.displayMode, .text)
        XCTAssertEqual(presentation.result.primaryOutput, "1709901296")
    }
}
