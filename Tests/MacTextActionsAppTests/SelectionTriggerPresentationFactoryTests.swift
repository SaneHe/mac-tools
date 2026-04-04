import XCTest
import MacTextActionsCore
@testable import MacTextActionsApp

final class SelectionTriggerPresentationFactoryTests: XCTestCase {
    func testBuildsErrorPanelWhenNoSelectionIsAvailable() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .failure(.noSelection)
        )

        XCTAssertEqual(presentation.selectedText, "")
        XCTAssertEqual(presentation.result.displayMode, .error)
        XCTAssertEqual(presentation.result.errorMessage, "未检测到选中文本")
        XCTAssertTrue(presentation.result.secondaryActions.isEmpty)
    }

    func testBuildsErrorPanelWhenApplicationDoesNotExposeSelection() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .failure(.unsupportedApplication)
        )

        XCTAssertEqual(presentation.selectedText, "")
        XCTAssertEqual(presentation.result.displayMode, .error)
        XCTAssertEqual(presentation.result.errorMessage, "当前应用暂不支持读取选中文本")
        XCTAssertTrue(presentation.result.secondaryActions.isEmpty)
    }

    func testBuildsErrorPanelWhenAccessibilityPermissionIsMissing() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .failure(.permissionDenied)
        )

        XCTAssertEqual(presentation.selectedText, "")
        XCTAssertEqual(presentation.result.displayMode, .error)
        XCTAssertEqual(presentation.result.errorMessage, "请先在系统设置中开启辅助功能权限")
        XCTAssertTrue(presentation.result.secondaryActions.isEmpty)
    }

    func testBuildsTransformResultForSuccessfulSelection() {
        let presentation = SelectionTriggerPresentationFactory.makePresentation(
            from: .success("{\"name\":\"codex\"}")
        )

        XCTAssertEqual(presentation.selectedText, "{\"name\":\"codex\"}")
        XCTAssertEqual(presentation.result.displayMode, .code)
        XCTAssertEqual(presentation.result.primaryOutput, "{\n  \"name\" : \"codex\"\n}")
        XCTAssertEqual(
            presentation.result.secondaryActions,
            [.copyResult, .replaceSelection, .compressJSON]
        )
    }
}
