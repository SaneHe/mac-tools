import Foundation

/// Applies the fixed v1 detection order from the product design docs.
public final class ContentDetector {
    public init() {}

    public func detect(_ input: String) -> DetectionResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\u{FEFF}")) // 去除 BOM

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

        if isURLEncodedString(trimmed) {
            return DetectionResult(kind: .url, normalizedInput: trimmed)
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

    private func isURLEncodedString(_ input: String) -> Bool {
        // 检查是否包含 URL 编码的特征字符
        // 1. 包含 % 后跟两个十六进制字符
        // 2. 或者包含 + 号（空格编码）
        // 3. 长度至少要有一定规模（避免误判）
        guard input.count > 10 else {
            return false
        }

        // 检查是否包含 URL 编码模式
        let urlPattern = "%[0-9A-Fa-f]{2}"
        guard let regex = try? NSRegularExpression(pattern: urlPattern, options: []) else {
            return false
        }

        let range = NSRange(input.startIndex..., in: input)
        let matches = regex.matches(in: input, options: [], range: range)

        // 至少要有 3 个 URL 编码序列才算 URL 编码字符串
        return matches.count >= 3
    }
}
