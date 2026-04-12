import XCTest
import MacTextActionsCore
@testable import MacTextActionsApp

final class SelectionTriggerPresentationFactoryTests: XCTestCase {
    private let replaceTarget = SelectionReplaceTarget { _ in true }

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
            from: .success(
                SelectionCapture(
                    text: "{\"name\":\"codex\"}",
                    replaceTarget: replaceTarget
                )
            )
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
        XCTAssertNotNil(presentation.replaceTarget)
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
        XCTAssertFalse(presentation.result.secondaryActions.contains(.replaceSelection))
        XCTAssertNil(presentation.replaceTarget)
    }

    func testBuildsPlainTextPresentationWithMD5AsTopRecommendation() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .success(
                SelectionCapture(
                    text: "plain text input",
                    replaceTarget: replaceTarget
                )
            )
        )

        XCTAssertEqual(presentation.title, "自动识别 · 文本")
        XCTAssertEqual(presentation.result.displayMode, .actionsOnly)
        XCTAssertEqual(presentation.result.secondaryActions.first, .generateMD5)
        XCTAssertEqual(presentation.result.actionsHintTitle, "未识别为 JSON 或时间类型")
        XCTAssertEqual(presentation.result.actionsHintMessage, "可以继续执行 MD5 或其他文本动作")
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
            from: .success(
                SelectionCapture(
                    text: "{\"name\":\"codex\",\"enabled\":true}",
                    replaceTarget: replaceTarget
                )
            ),
            mode: .jsonCompress
        )

        XCTAssertEqual(presentation.title, "指定模式 · JSON Compress")
        XCTAssertEqual(presentation.result.displayMode, .code)
        XCTAssertEqual(presentation.result.primaryOutput, "{\"enabled\":true,\"name\":\"codex\"}")
    }

    func testBuildsExplicitMD5Presentation() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .success(
                SelectionCapture(
                    text: "hello",
                    replaceTarget: replaceTarget
                )
            ),
            mode: .md5
        )

        XCTAssertEqual(presentation.title, "指定模式 · MD5")
        XCTAssertEqual(presentation.result.displayMode, .text)
        XCTAssertEqual(presentation.result.primaryOutput, "5d41402abc4b2a76b9719d911017c592")
        XCTAssertEqual(presentation.result.optionAction?.buttonTitle, "转大写")
    }

    func testMakeResultKeepsMD5ExecutionModeWhenSwitchingOptionAction() {
        let result = SelectionTriggerPresentationFactory.makeResult(
            from: "hello",
            mode: .md5,
            context: TransformContext(md5LetterCase: .uppercase)
        )

        XCTAssertEqual(result.displayMode, .text)
        XCTAssertEqual(result.primaryOutput, "5D41402ABC4B2A76B9719D911017C592")
        XCTAssertEqual(result.optionAction?.buttonTitle, "转小写")
    }

    func testBuildsAutomaticDateToTimestampPresentation() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .success(
                SelectionCapture(
                    text: "2024-03-08T12:34:56Z",
                    replaceTarget: replaceTarget
                )
            )
        )

        XCTAssertEqual(presentation.title, "自动识别 · 日期")
        XCTAssertEqual(presentation.result.displayMode, .text)
        XCTAssertEqual(presentation.result.primaryOutput, "1709901296")
        XCTAssertEqual(presentation.result.optionAction?.buttonTitle, "转毫秒")
    }

    func testRemovesReplaceActionWhenSuccessfulCaptureDoesNotProvideReplaceTarget() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .success(
                SelectionCapture(
                    text: "{\"name\":\"codex\"}",
                    replaceTarget: nil
                )
            )
        )

        XCTAssertEqual(presentation.result.displayMode, .code)
        XCTAssertFalse(presentation.result.secondaryActions.contains(.replaceSelection))
        XCTAssertNil(presentation.replaceTarget)
    }
}
