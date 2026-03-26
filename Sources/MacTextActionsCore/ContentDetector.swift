import Foundation

/// Applies the fixed v1 detection order from the product design docs.
public final class ContentDetector {
    public init() {}

    public func detect(_ input: String) -> DetectionResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Keep JSON ahead of every other type so structured input never falls through to plain text.
        if let result = detectJSONCandidate(trimmed) {
            return result
        }

        if isLikelyTimestamp(trimmed) {
            return DetectionResult(kind: .timestamp, normalizedInput: trimmed)
        }

        if isParseableDateString(trimmed) {
            return DetectionResult(kind: .dateString, normalizedInput: trimmed)
        }

        return DetectionResult(kind: .plainText, normalizedInput: input)
    }

    private func detectJSONCandidate(_ input: String) -> DetectionResult? {
        // Fast-reject obvious non-JSON input before paying the parsing cost.
        guard let firstCharacter = input.first, firstCharacter == "{" || firstCharacter == "[" else {
            return nil
        }

        guard let data = input.data(using: .utf8) else {
            return DetectionResult(
                kind: .invalidJSON,
                normalizedInput: input,
                errorMessage: "无法将所选文本编码为 UTF-8。"
            )
        }

        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            return DetectionResult(kind: .json, normalizedInput: input)
        } catch {
            return DetectionResult(
                kind: .invalidJSON,
                normalizedInput: input,
                errorMessage: "JSON 格式无效，请检查语法。"
            )
        }
    }

    private func isLikelyTimestamp(_ input: String) -> Bool {
        // v1 intentionally limits timestamp detection to common 10/13-digit Unix values.
        guard input.count == 10 || input.count == 13 else {
            return false
        }

        return input.allSatisfy(\.isNumber)
    }

    private func isParseableDateString(_ input: String) -> Bool {
        DateParsers.makeDate(from: input) != nil
    }
}
