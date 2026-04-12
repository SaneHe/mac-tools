import XCTest
@testable import MacTextActionsCore

final class TransformEngineTests: XCTestCase {
    func testFormatsJSONAndExposesCompressAction() {
        let detector = ContentDetector()
        let engine = TransformEngine()

        let detection = detector.detect("{\"b\":2,\"a\":1}")
        let result = engine.transform(input: "{\"b\":2,\"a\":1}", detection: detection)

        XCTAssertEqual(result.displayMode, .code)
        XCTAssertTrue(result.primaryOutput?.contains("\"b\"") == true || result.primaryOutput?.contains("\"a\"") == true)
        XCTAssertEqual(result.secondaryActions, [.copyResult, .replaceSelection, .compressJSON])
    }

    func testMarksInvalidJSONAsError() {
        let detector = ContentDetector()
        let engine = TransformEngine()

        let detection = detector.detect("{\"name\":}")
        let result = engine.transform(input: "{\"name\":}", detection: detection)

        XCTAssertEqual(result.displayMode, .error)
        XCTAssertNotNil(result.errorMessage)
    }

    func testUsesChineseFallbackForInvalidJSONError() {
        let engine = TransformEngine()
        let detection = DetectionResult(kind: .invalidJSON, normalizedInput: "{\"name\":}", errorMessage: nil)

        let result = engine.transform(input: "{\"name\":}", detection: detection)

        XCTAssertEqual(result.errorMessage, "JSON 校验失败。")
    }

    func testConvertsTimestampToLocalDateTimeAndExposesCopyAction() {
        let detector = ContentDetector()
        let engine = TransformEngine()

        let detection = detector.detect("1710000000")
        let result = engine.transform(input: "1710000000", detection: detection)

        XCTAssertEqual(result.displayMode, .text)
        XCTAssertEqual(result.secondaryActions, [.copyResult, .replaceSelection])
        XCTAssertFalse(result.primaryOutput?.isEmpty ?? true)
    }

    func testConvertsThirteenDigitTimestampToLocalDateTime() {
        let detector = ContentDetector()
        let engine = TransformEngine()

        let detection = detector.detect("1710000000123")
        let result = engine.transform(input: "1710000000123", detection: detection)

        XCTAssertEqual(result.displayMode, .text)
        XCTAssertEqual(result.secondaryActions, [.copyResult, .replaceSelection])
        XCTAssertFalse(result.primaryOutput?.isEmpty ?? true)
    }

    func testUsesChineseTimestampParseError() {
        let engine = TransformEngine()
        let detection = DetectionResult(kind: .timestamp, normalizedInput: "abc")

        let result = engine.transform(input: "abc", detection: detection)

        XCTAssertEqual(result.displayMode, .error)
        XCTAssertEqual(result.errorMessage, "无法解析所选时间戳。")
    }

    func testConvertsDateStringToUnixTimestamp() {
        let detector = ContentDetector()
        let engine = TransformEngine()

        let detection = detector.detect("2024-03-08T12:34:56Z")
        let result = engine.transform(input: "2024-03-08T12:34:56Z", detection: detection)

        XCTAssertEqual(result.displayMode, .text)
        XCTAssertEqual(result.primaryOutput, "1709901296")
    }

    func testDateStringDefaultsToSecondPrecisionOptionAction() {
        let detector = ContentDetector()
        let engine = TransformEngine()
        let detection = detector.detect("2024-03-08T12:34:56Z")

        let result = engine.transform(
            input: "2024-03-08T12:34:56Z",
            detection: detection,
            context: TransformContext(timestampPrecision: .seconds)
        )

        XCTAssertEqual(result.primaryOutput, "1709901296")
        XCTAssertEqual(result.optionAction?.buttonTitle, "转毫秒")
        XCTAssertEqual(
            result.optionAction?.nextContext,
            TransformContext(timestampPrecision: .milliseconds)
        )
    }

    func testDateStringCanSwitchToMillisecondPrecisionOptionAction() {
        let detector = ContentDetector()
        let engine = TransformEngine()
        let detection = detector.detect("2024-03-08T12:34:56Z")

        let result = engine.transform(
            input: "2024-03-08T12:34:56Z",
            detection: detection,
            context: TransformContext(timestampPrecision: .milliseconds)
        )

        XCTAssertEqual(result.primaryOutput, "1709901296000")
        XCTAssertEqual(result.optionAction?.buttonTitle, "转秒级")
        XCTAssertEqual(
            result.optionAction?.nextContext,
            TransformContext(timestampPrecision: .seconds)
        )
    }

    func testUsesChineseDateStringParseError() {
        let engine = TransformEngine()
        let detection = DetectionResult(kind: .dateString, normalizedInput: "not-a-date")

        let result = engine.transform(input: "not-a-date", detection: detection)

        XCTAssertEqual(result.displayMode, .error)
        XCTAssertEqual(result.errorMessage, "无法解析所选日期字符串。")
    }

    func testPlainTextExposesMD5AsSecondaryAction() {
        let detector = ContentDetector()
        let engine = TransformEngine()

        let detection = detector.detect("hello")
        let result = engine.transform(input: "hello", detection: detection)

        XCTAssertEqual(result.displayMode, .actionsOnly)
        XCTAssertEqual(result.secondaryActions.first, .generateMD5)
        XCTAssertTrue(result.secondaryActions.contains(.urlEncode))
        XCTAssertTrue(result.secondaryActions.contains(.urlDecode))
        XCTAssertEqual(result.actionsHintTitle, "未识别为 JSON 或时间类型")
        XCTAssertEqual(result.actionsHintMessage, "可以继续执行 MD5 或其他文本动作")
    }

    func testExplicitMD5DefaultsToLowercaseAndExposesUppercaseOptionAction() {
        let engine = TransformEngine()

        let result = engine.transformMD5(input: "hello")

        XCTAssertEqual(result.displayMode, .text)
        XCTAssertEqual(result.primaryOutput, "5d41402abc4b2a76b9719d911017c592")
        XCTAssertEqual(result.optionAction?.buttonTitle, "转大写")
        XCTAssertEqual(
            result.optionAction?.nextContext,
            TransformContext(md5LetterCase: .uppercase)
        )
    }

    func testExplicitMD5CanSwitchToUppercaseAndExposeLowercaseOptionAction() {
        let engine = TransformEngine()

        let result = engine.transformMD5(
            input: "hello",
            context: TransformContext(md5LetterCase: .uppercase)
        )

        XCTAssertEqual(result.displayMode, .text)
        XCTAssertEqual(result.primaryOutput, "5D41402ABC4B2A76B9719D911017C592")
        XCTAssertEqual(result.optionAction?.buttonTitle, "转小写")
        XCTAssertEqual(
            result.optionAction?.nextContext,
            TransformContext(md5LetterCase: .lowercase)
        )
    }

    func testEditingDateStringPreservesSecondPrecisionWhenOriginalTimestampWasTenDigits() throws {
        let engine = TransformEngine()
        let detector = ContentDetector()
        let originalTimestamp = "1710000000"
        let initialDetection = detector.detect(originalTimestamp)
        let initialResult = engine.transform(input: originalTimestamp, detection: initialDetection)
        let editableValue = try XCTUnwrap(initialResult.primaryOutput)
        let detection = detector.detect(editableValue)
        let context = TransformContext(timestampPrecision: .seconds)

        let result = engine.transformForEditing(
            input: editableValue,
            detection: detection,
            context: context
        )

        XCTAssertEqual(result.displayMode, .text)
        XCTAssertEqual(result.primaryOutput, originalTimestamp)
    }

    func testEditingDateStringPreservesMillisecondPrecisionWhenOriginalTimestampWasThirteenDigits() throws {
        let engine = TransformEngine()
        let detector = ContentDetector()
        let originalTimestamp = "1710000000123"
        let initialDetection = detector.detect(originalTimestamp)
        let initialResult = engine.transform(input: originalTimestamp, detection: initialDetection)
        let editableValue = try XCTUnwrap(initialResult.primaryOutput)
        let detection = detector.detect(editableValue)
        let context = TransformContext(timestampPrecision: .milliseconds)

        let result = engine.transformForEditing(
            input: editableValue,
            detection: detection,
            context: context
        )

        XCTAssertEqual(result.displayMode, .text)
        XCTAssertEqual(result.primaryOutput, "1710000000000")
    }
}
