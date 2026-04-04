import Foundation

/// Builds the primary result plus secondary actions for the detected content kind.
public final class TransformEngine {
    public init() {}

    public func transform(input: String, detection: DetectionResult) -> TransformResult {
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
            return transformDateString(input)
        case .url:
            return transformURL(input)
        case .plainText:
            // Plain text keeps the original selection unchanged and only exposes explicit actions.
            return TransformResult(
                primaryOutput: nil,
                secondaryActions: [.copyResult, .replaceSelection, .urlEncode, .urlDecode, .generateMD5, .createReminder],
                displayMode: .actionsOnly
            )
        }
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

    private func transformDateString(_ input: String) -> TransformResult {
        guard let date = DateParsers.makeDate(from: input) else {
            return TransformResult(
                primaryOutput: nil,
                secondaryActions: [],
                displayMode: .error,
                errorMessage: "无法解析所选日期字符串。"
            )
        }

        return TransformResult(
            primaryOutput: String(Int(date.timeIntervalSince1970)),
            secondaryActions: [.copyResult, .replaceSelection],
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
}
