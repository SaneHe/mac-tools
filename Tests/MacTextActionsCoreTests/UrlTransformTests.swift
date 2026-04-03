import XCTest
@testable import MacTextActionsCore

final class UrlTransformTests: XCTestCase {
    func testEncodeSpacesToPercent20() {
        let result = UrlTransform.encode("hello world")
        XCTAssertEqual(result, "hello%20world")
    }

    func testEncodeSpecialCharacters() {
        // urlQueryAllowed encodes # but not = & ?
        let result = UrlTransform.encode("test#value")
        XCTAssertEqual(result, "test%23value")
    }

    func testEncodeUnicodeCharacters() {
        let result = UrlTransform.encode("你好")
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("%"))
    }

    func testDecodePercent20ToSpaces() {
        let result = UrlTransform.decode("hello%20world")
        XCTAssertEqual(result, "hello world")
    }

    func testDecodeSpecialCharacters() {
        let result = UrlTransform.decode("name%3Dtest%26value%3D1")
        XCTAssertEqual(result, "name=test&value=1")
    }

    func testDecodeUnicodeCharacters() {
        let result = UrlTransform.decode("%E4%BD%A0%E5%A5%BD")
        XCTAssertEqual(result, "你好")
    }

    func testEncodeDecodeRoundTrip() {
        let original = "hello world! 你好 @#$%"
        let encoded = UrlTransform.encode(original)
        let decoded = encoded.flatMap { UrlTransform.decode($0) }
        XCTAssertEqual(decoded, original)
    }

    func testDecodeInvalidPercentEncodingReturnsNil() {
        // 无效的百分号编码应返回 nil
        let result = UrlTransform.decode("hello%ZZ")
        XCTAssertNil(result)
    }
}
