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

    func testDetectsJSONWithBOM() {
        let detector = ContentDetector()

        // 测试带 BOM（零宽无间断空格 U+FEFF）的 JSON
        let jsonWithBOM = "\u{FEFF}{\"name\":\"Ada\"}"
        let result = detector.detect(jsonWithBOM)

        XCTAssertEqual(result.kind, .json)
    }

    func testFallsBackToPlainText() {
        let detector = ContentDetector()

        let result = detector.detect("plain text")

        XCTAssertEqual(result.kind, .plainText)
    }

    func testDetectsURLEncodedString() {
        let detector = ContentDetector()

        // 包含多个 URL 编码参数的字符串
        let urlEncoded = "/click?source=toutiao&project=reader_free&adid=1861303139698779&ua=Mozilla%2F5.0%20Linux%3B%20Android"
        let result = detector.detect(urlEncoded)

        XCTAssertEqual(result.kind, .url)
    }

    func testDetectsPlainTextForShortStrings() {
        let detector = ContentDetector()

        // 短字符串不应该被识别为 URL
        let short = "test%20string"
        let result = detector.detect(short)

        XCTAssertEqual(result.kind, .plainText)
    }
}
