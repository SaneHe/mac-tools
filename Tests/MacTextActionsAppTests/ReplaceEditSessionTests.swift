import XCTest
import MacTextActionsCore
@testable import MacTextActionsApp

final class ReplaceEditSessionTests: XCTestCase {
    func testBeginEditingUsesPrimaryResultAsEditableValue() throws {
        let result = TransformResult(
            primaryOutput: "2024-03-09 16:00:00",
            secondaryActions: [.copyResult, .replaceSelection],
            displayMode: .text
        )

        let session = try XCTUnwrap(
            ReplaceEditSession.begin(
                selectedText: "1710000000",
                result: result
            )
        )

        XCTAssertEqual(session.mode, .editing)
        XCTAssertEqual(session.originalSelectedText, "1710000000")
        XCTAssertEqual(session.editableText, "2024-03-09 16:00:00")
    }

    func testBeginEditingReturnsNilWhenResultHasNoPrimaryOutput() {
        let result = TransformResult(
            primaryOutput: nil,
            secondaryActions: [.copyResult, .replaceSelection],
            displayMode: .actionsOnly
        )

        let session = ReplaceEditSession.begin(
            selectedText: "hello",
            result: result
        )

        XCTAssertNil(session)
    }

    func testTimestampSelectionBuildsMillisecondPrecisionContext() throws {
        let result = TransformResult(
            primaryOutput: "2024-03-09 16:00:00",
            secondaryActions: [.copyResult, .replaceSelection],
            displayMode: .text
        )

        let session = try XCTUnwrap(
            ReplaceEditSession.begin(
                selectedText: "1710000000123",
                result: result
            )
        )

        XCTAssertEqual(session.transformContext.timestampPrecision, .milliseconds)
    }

    func testLiveResultUsesEditingTransformContextForTimestampRoundTrip() throws {
        let detector = ContentDetector()
        let engine = TransformEngine()
        let originalTimestamp = "1710000000123"
        let initialDetection = detector.detect(originalTimestamp)
        let result = engine.transform(input: originalTimestamp, detection: initialDetection)
        let session = try XCTUnwrap(
            ReplaceEditSession.begin(
                selectedText: originalTimestamp,
                result: result
            )
        )

        let liveResult = session.makeLiveResult(for: session.editableText)

        XCTAssertEqual(liveResult.displayMode, .text)
        XCTAssertEqual(liveResult.primaryOutput, "1710000000000")
    }
}
