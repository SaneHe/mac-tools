import Foundation

/// Builds the primary result plus secondary actions for the detected content kind.
public final class TransformEngine {
    public init() {}

    public func transform(input: String, detection: DetectionResult) -> TransformResult {
        makeTransformResult(input: input, detection: detection, context: TransformContext())
    }

    public func transform(
        input: String,
        detection: DetectionResult,
        context: TransformContext
    ) -> TransformResult {
        makeTransformResult(input: input, detection: detection, context: context)
    }

    public func transformForEditing(
        input: String,
        detection: DetectionResult,
        context: TransformContext
    ) -> TransformResult {
        makeTransformResult(input: input, detection: detection, context: context)
    }

    private func makeTransformResult(
        input: String,
        detection: DetectionResult,
        context: TransformContext
    ) -> TransformResult {
        switch detection.kind {
        case .json:
            return transformJSON(input)
        case .invalidJSON:
            return TransformResult(
                primaryOutput: nil,
                secondaryActions: [],
                displayMode: .error,
                errorMessage: detection.errorMessage ?? "JSON 校验失败。"
            )
        case .timestamp:
            return transformTimestamp(input)
        case .dateString:
            return transformDateString(input, context: context)
        case .url:
            return transformURL(input)
        case .plainText:
            // Plain text keeps the original selection unchanged and only exposes explicit actions.
            return TransformResult(
                primaryOutput: nil,
                secondaryActions: [.generateMD5, .urlDecode, .urlEncode],
                actionsHintTitle: "未识别为 JSON 或时间类型",
                actionsHintMessage: "可以继续执行 MD5 或其他文本动作",
                displayMode: .actionsOnly
            )
        }
    }

    public func transformMD5(
        input: String,
        context: TransformContext = TransformContext()
    ) -> TransformResult {
        guard let output = SecondaryActionPerformer.md5Hex(
            for: input,
            letterCase: context.md5LetterCase
        ) else {
            return TransformResult(
                primaryOutput: nil,
                secondaryActions: [],
                displayMode: .error,
                errorMessage: "MD5 转换失败。"
            )
        }

        return TransformResult(
            primaryOutput: output,
            secondaryActions: [.copyResult, .replaceSelection],
            optionAction: md5OptionAction(for: context),
            displayMode: .text
        )
    }

    private func transformJSON(_ input: String) -> TransformResult {
        guard let data = input.data(using: .utf8) else {
            return TransformResult(
                primaryOutput: nil,
                secondaryActions: [],
                displayMode: .error,
                errorMessage: "无法将所选文本编码为 UTF-8。"
            )
        }

        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let prettyPrintedData = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
            let output = String(data: prettyPrintedData, encoding: .utf8) ?? input
            return TransformResult(
                primaryOutput: output,
                secondaryActions: [.copyResult, .replaceSelection, .compressJSON],
                displayMode: .code
            )
        } catch {
            return TransformResult(
                primaryOutput: nil,
                secondaryActions: [],
                displayMode: .error,
                errorMessage: "JSON 格式无效，请检查语法。"
            )
        }
    }

    private func transformTimestamp(_ input: String) -> TransformResult {
        guard let date = DateParsers.makeDateFromTimestamp(input) else {
            return TransformResult(
                primaryOutput: nil,
                secondaryActions: [],
                displayMode: .error,
                errorMessage: "无法解析所选时间戳。"
            )
        }

        return TransformResult(
            primaryOutput: DateParsers.localDateTimeFormatter.string(from: date),
            secondaryActions: [.copyResult, .replaceSelection],
            displayMode: .text
        )
    }

    private func transformDateString(_ input: String, context: TransformContext) -> TransformResult {
        guard let date = DateParsers.makeDate(from: input) else {
            return TransformResult(
                primaryOutput: nil,
                secondaryActions: [],
                displayMode: .error,
                errorMessage: "无法解析所选日期字符串。"
            )
        }

        return TransformResult(
            primaryOutput: timestampOutput(from: date, context: context),
            secondaryActions: [.copyResult, .replaceSelection],
            optionAction: timestampOptionAction(for: context),
            displayMode: .text
        )
    }

    private func transformURL(_ input: String) -> TransformResult {
        guard let decoded = UrlTransform.decode(input) else {
            return TransformResult(
                primaryOutput: nil,
                secondaryActions: [],
                displayMode: .error,
                errorMessage: "无法解码 URL。"
            )
        }

        return TransformResult(
            primaryOutput: decoded,
            secondaryActions: [.copyResult, .replaceSelection, .urlEncode],
            displayMode: .text
        )
    }

    private func timestampOutput(from date: Date, context: TransformContext) -> String {
        switch context.timestampPrecision {
        case .seconds, .none:
            return String(Int(date.timeIntervalSince1970))
        case .milliseconds:
            return String(Int(date.timeIntervalSince1970 * 1000))
        }
    }

    private func timestampOptionAction(for context: TransformContext) -> OptionAction {
        switch context.timestampPrecision {
        case .milliseconds:
            return OptionAction(
                buttonTitle: "转秒级",
                nextContext: TransformContext(
                    timestampPrecision: .seconds,
                    md5LetterCase: context.md5LetterCase
                )
            )
        case .seconds, .none:
            return OptionAction(
                buttonTitle: "转毫秒",
                nextContext: TransformContext(
                    timestampPrecision: .milliseconds,
                    md5LetterCase: context.md5LetterCase
                )
            )
        }
    }

    private func md5OptionAction(for context: TransformContext) -> OptionAction {
        switch context.md5LetterCase {
        case .lowercase:
            return OptionAction(
                buttonTitle: "转大写",
                nextContext: TransformContext(
                    timestampPrecision: context.timestampPrecision,
                    md5LetterCase: .uppercase
                )
            )
        case .uppercase:
            return OptionAction(
                buttonTitle: "转小写",
                nextContext: TransformContext(
                    timestampPrecision: context.timestampPrecision,
                    md5LetterCase: .lowercase
                )
            )
        }
    }
}
