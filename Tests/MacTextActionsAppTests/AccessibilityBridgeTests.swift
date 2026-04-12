import XCTest
@testable import MacTextActionsApp

final class AccessibilityBridgeTests: XCTestCase {
    func testSelectionCaptureReportsReplaceAvailabilityFromTargetPresence() {
        let captureWithTarget = SelectionCapture(
            text: "hello",
            replaceTarget: SelectionReplaceTarget { _ in true }
        )
        let captureWithoutTarget = SelectionCapture(
            text: "hello",
            replaceTarget: nil
        )

        XCTAssertTrue(captureWithTarget.canReplaceSelection)
        XCTAssertFalse(captureWithoutTarget.canReplaceSelection)
    }

    func testReplaceSelectedTextReturnsFalseWhenTargetIsMissing() {
        let didReplace = AccessibilityBridge.shared.replaceSelectedText(
            with: "new value",
            using: nil
        )

        XCTAssertFalse(didReplace)
    }

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

    func testFallbackRestoresOriginalClipboardWhenFallbackTextIsStillCurrent() {
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
        XCTAssertEqual(pasteboard.text, "旧内容")
    }

    func testFallbackDoesNotOverwriteClipboardWhenUserChangedItAgain() {
        let pasteboard = TestPasteboard(changeCount: 1, text: "旧内容")
        let copier = TestSelectionCopier {
            pasteboard.changeCount = 2
            pasteboard.text = "新选中文本"
        }
        let waiter = TestClipboardWaiter { onObservedClipboardUpdate in
            onObservedClipboardUpdate?()
            pasteboard.changeCount = 3
            pasteboard.text = "用户后续复制"
        }
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
        XCTAssertEqual(pasteboard.text, "用户后续复制")
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

    func replaceContents(with text: String?) {
        self.text = text
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
    private let onWait: ((() -> Void)?) -> Void

    init(onWait: @escaping ((() -> Void)?) -> Void = { _ in }) {
        self.onWait = onWait
    }

    func waitForClipboardUpdate(onObservedClipboardUpdate: (() -> Void)?) {
        waitInvocationCount += 1
        onWait(onObservedClipboardUpdate)
    }
}
