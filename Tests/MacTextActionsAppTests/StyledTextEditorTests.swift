import AppKit
import XCTest
@testable import MacTextActionsApp

final class StyledTextEditorTests: XCTestCase {
    func testVerticalInsetCentersSingleLineContentWhenSpaceIsAvailable() {
        let inset = CenteredTextLayout.verticalInset(
            minHeight: 220,
            contentHeight: 14
        )

        XCTAssertEqual(inset, 103)
    }

    func testVerticalInsetKeepsMinimumPaddingForTallContent() {
        let inset = CenteredTextLayout.verticalInset(
            minHeight: 220,
            contentHeight: 240
        )

        XCTAssertEqual(inset, 16)
    }

    func testTextViewRecomputesInsetAfterTextChanges() {
        let textView = CenteredTextView(frame: NSRect(x: 0, y: 0, width: 320, height: 220))
        textView.minHeight = 220
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = false
        textView.textContainer?.containerSize = NSSize(
            width: 320,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true

        textView.string = ""
        textView.updateTextContainerInset()
        let emptyInset = textView.textContainerInset.height

        textView.string = String(repeating: "1234567890 ", count: 20)
        textView.updateTextContainerInset()
        let pastedInset = textView.textContainerInset.height

        XCTAssertLessThan(pastedInset, emptyInset)
        XCTAssertGreaterThanOrEqual(pastedInset, 16)
    }

    func testTextViewReportsUpdatedTextWhenContentChanges() {
        let expectation = expectation(description: "文本变化会回传最新值")
        let textView = CenteredTextView(frame: NSRect(x: 0, y: 0, width: 320, height: 220))
        textView.onTextDidChange = { text in
            XCTAssertEqual(text, "12312312")
            expectation.fulfill()
        }

        textView.string = "12312312"
        textView.didChangeText()

        wait(for: [expectation], timeout: 1.0)
    }

    func testSelectableCopyableTextUsesScrollViewBackedTextView() {
        let scrollView = SelectableCopyableText.makeConfiguredScrollView(
            text: "hello",
            minHeight: 120
        )

        XCTAssertTrue(scrollView.documentView is CopyableTextView)
        XCTAssertEqual((scrollView.documentView as? CopyableTextView)?.string, "hello")
    }
}
