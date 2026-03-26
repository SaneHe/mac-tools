import XCTest
@testable import MacTextActionsCore

final class ContentDetectionTests: XCTestCase {
    func testDetectsValidJSONBeforePlainText() {
        let detector = ContentDetector()

        let result = detector.detect("{\"name\":\"Ada\"}")

        XCTAssertEqual(result.kind, .json)
    }

    func testDetectsInvalidJSONAsDistinctKind() {
        let detector = ContentDetector()

        let result = detector.detect("{\"name\":}")

        XCTAssertEqual(result.kind, .invalidJSON)
    }

    func testDetectsTimestampBeforeDateString() {
        let detector = ContentDetector()

        let result = detector.detect("1710000000")

        XCTAssertEqual(result.kind, .timestamp)
    }

    func testDetectsParseableDateStringAfterTimestamp() {
        let detector = ContentDetector()

        let result = detector.detect("2024-03-08T12:34:56Z")

        XCTAssertEqual(result.kind, .dateString)
    }

    func testFallsBackToPlainText() {
        let detector = ContentDetector()

        let result = detector.detect("plain text")

        XCTAssertEqual(result.kind, .plainText)
    }
}
