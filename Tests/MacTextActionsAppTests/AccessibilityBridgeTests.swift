import XCTest
@testable import MacTextActionsApp

final class AccessibilityBridgeTests: XCTestCase {
    func testFallbackUsesCopiedClipboardTextAfterTriggeringCopy() {
        let pasteboard = TestPasteboard(changeCount: 1, text: "旧内容")
        let copier = TestSelectionCopier {
            pasteboard.changeCount = 2
            pasteboard.text = "新选中文本"
        }
        let waiter = TestClipboardWaiter()
        let resolver = SelectionCopyFallbackResolver(
            pasteboard: pasteboard,
            selectionCopier: copier,
            waitStrategy: waiter
        )

        let result = resolver.resolve(failure: .unsupportedApplication)

        XCTAssertEqual(
            result,
            .fallbackSuccess(text: "新选中文本", failure: .unsupportedApplication)
        )
        XCTAssertEqual(copier.copyInvocationCount, 1)
        XCTAssertEqual(waiter.waitInvocationCount, 1)
    }

    func testFallbackDoesNotReuseClipboardWhenCopyDidNotUpdatePasteboard() {
        let pasteboard = TestPasteboard(changeCount: 3, text: "旧内容")
        let copier = TestSelectionCopier()
        let waiter = TestClipboardWaiter()
        let resolver = SelectionCopyFallbackResolver(
            pasteboard: pasteboard,
            selectionCopier: copier,
            waitStrategy: waiter
        )

        let result = resolver.resolve(failure: .noSelection)

        XCTAssertEqual(result, .failure(.noSelection))
        XCTAssertEqual(copier.copyInvocationCount, 1)
        XCTAssertEqual(waiter.waitInvocationCount, 1)
    }

    func testFallbackReturnsFailureWhenCopiedClipboardTextIsBlank() {
        let pasteboard = TestPasteboard(changeCount: 5, text: "旧内容")
        let copier = TestSelectionCopier {
            pasteboard.changeCount = 6
            pasteboard.text = "   "
        }
        let waiter = TestClipboardWaiter()
        let resolver = SelectionCopyFallbackResolver(
            pasteboard: pasteboard,
            selectionCopier: copier,
            waitStrategy: waiter
        )

        let result = resolver.resolve(failure: .unsupportedApplication)

        XCTAssertEqual(result, .failure(.unsupportedApplication))
    }
}

private final class TestPasteboard: PasteboardReading {
    var changeCount: Int
    var text: String?

    init(changeCount: Int, text: String?) {
        self.changeCount = changeCount
        self.text = text
    }

    func string(forType type: NSPasteboard.PasteboardType) -> String? {
        text
    }
}

private final class TestSelectionCopier: SelectionCopying {
    private let onCopy: () -> Void
    private(set) var copyInvocationCount = 0

    init(onCopy: @escaping () -> Void = {}) {
        self.onCopy = onCopy
    }

    func copyCurrentSelection() {
        copyInvocationCount += 1
        onCopy()
    }
}

private final class TestClipboardWaiter: ClipboardFallbackWaiting {
    private(set) var waitInvocationCount = 0

    func waitForClipboardUpdate() {
        waitInvocationCount += 1
    }
}
