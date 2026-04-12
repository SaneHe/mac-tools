import AppKit
import SwiftUI
import XCTest
@testable import MacTextActionsApp

final class StyledTextEditorTests: XCTestCase {
    func testVerticalInsetUsesTopPaddingForSingleLineContent() {
        let inset = EditorTextLayout.verticalInset(
            minHeight: 220,
            contentHeight: 14
        )

        XCTAssertEqual(inset, 16)
    }

    func testVerticalInsetKeepsMinimumPaddingForTallContent() {
        let inset = EditorTextLayout.verticalInset(
            minHeight: 220,
            contentHeight: 240
        )

        XCTAssertEqual(inset, 16)
    }

    func testTextViewKeepsStableTopInsetAfterTextChanges() {
        let textView = EditorTextView(frame: NSRect(x: 0, y: 0, width: 320, height: 220))
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

        XCTAssertEqual(emptyInset, 16)
        XCTAssertEqual(pastedInset, 16)
        XCTAssertGreaterThanOrEqual(pastedInset, 16)
    }

    func testTextViewReportsUpdatedTextWhenContentChanges() {
        let expectation = expectation(description: "文本变化会回传最新值")
        let textView = EditorTextView(frame: NSRect(x: 0, y: 0, width: 320, height: 220))
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

    func testSelectableCopyableTextPreservesRequestedMinimumHeight() {
        let scrollView = SelectableCopyableText.makeConfiguredScrollView(
            text: "hello",
            minHeight: 168
        )

        XCTAssertEqual((scrollView.documentView as? CopyableTextView)?.minHeight, 168)
    }

    func testSelectableCopyableTextUsesMinimumHeightAsIntrinsicHeight() {
        let scrollView = SelectableCopyableText.makeConfiguredScrollView(
            text: "2026-04-12 12:34:56",
            minHeight: 96
        )

        XCTAssertEqual(scrollView.intrinsicContentSize.height, 96)
    }

    func testCopyableTextViewExpandsHeightForLongStructuredContent() throws {
        let scrollView = SelectableCopyableText.makeConfiguredScrollView(
            text: """
            {
              "code": 0,
              "data": {
                "list": [
                  {
                    "account_id": 104789820692,
                    "account_name": "七猫免费一管家账户"
                  },
                  {
                    "account_id": 204789820692,
                    "account_name": "第二条记录"
                  }
                ]
              }
            }
            """,
            minHeight: 96
        )

        let textView = try XCTUnwrap(scrollView.documentView as? CopyableTextView)

        XCTAssertGreaterThan(textView.frame.height, 96)
    }

    func testCopyableTextViewReportsCopySuccessToContainer() {
        let expectation = expectation(description: "双击复制会回传成功事件")
        let textView = CopyableTextView(frame: NSRect(x: 0, y: 0, width: 240, height: 120))
        textView.string = "hello world"
        textView.setSelectedRange(NSRange(location: 0, length: 5))
        textView.onCopySucceeded = {
            expectation.fulfill()
        }

        textView.copySelectedTextToPasteboardForTesting()

        wait(for: [expectation], timeout: 1.0)
    }

    func testEditorTextViewReportsCopySuccessToContainer() {
        let expectation = expectation(description: "编辑器双击复制会回传成功事件")
        let textView = EditorTextView(frame: NSRect(x: 0, y: 0, width: 240, height: 120))
        textView.string = "copy me"
        textView.setSelectedRange(NSRange(location: 0, length: 4))
        textView.onCopySucceeded = {
            expectation.fulfill()
        }

        textView.copySelectedTextToPasteboardForTesting()

        wait(for: [expectation], timeout: 1.0)
    }

    func testWorkspaceFieldSurfaceStyleUsesSharedRoundedLightPalette() {
        XCTAssertEqual(ToolFieldSurfaceStyle.workspace.cornerRadius, 16)
        XCTAssertEqual(ToolFieldSurfaceStyle.workspace.borderWidth, SettingsChrome.borderWidth)

        let fill = rgba(from: ToolFieldSurfaceStyle.workspace.fillColor)
        let border = rgba(from: ToolFieldSurfaceStyle.workspace.borderColor)

        XCTAssertGreaterThanOrEqual(fill.red, 0.95)
        XCTAssertGreaterThanOrEqual(fill.green, 0.96)
        XCTAssertGreaterThanOrEqual(border.red, 0.82)
        XCTAssertGreaterThanOrEqual(border.green, 0.86)
    }

    func testPopoverFieldSurfaceStyleUsesSharedTranslucentPanelPalette() {
        XCTAssertEqual(ToolFieldSurfaceStyle.popover.cornerRadius, 12)
        XCTAssertEqual(ToolFieldSurfaceStyle.popover.borderWidth, 1)

        let fill = rgba(from: ToolFieldSurfaceStyle.popover.fillColor)
        let border = rgba(from: ToolFieldSurfaceStyle.popover.borderColor)

        XCTAssertGreaterThan(fill.alpha, 0.07)
        XCTAssertLessThan(fill.alpha, 0.10)
        XCTAssertGreaterThan(border.alpha, 0.15)
        XCTAssertLessThan(border.alpha, 0.17)
    }

    private func rgba(from color: Color) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? .clear
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}
