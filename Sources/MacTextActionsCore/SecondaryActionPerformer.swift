import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Stateless helpers for secondary actions that operate on the current selection.
public enum SecondaryActionPerformer {
    public static func compressedJSON(from input: String) -> String? {
        guard let data = input.data(using: .utf8) else {
            return nil
        }

        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let compressedData = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
            return String(data: compressedData, encoding: .utf8)
        } catch {
            return nil
        }
    }

    public static func md5Hex(
        for input: String,
        letterCase: MD5LetterCase = .lowercase
    ) -> String? {
        #if canImport(CryptoKit)
        let digest = Insecure.MD5.hash(data: Data(input.utf8))
        let format = switch letterCase {
        case .lowercase:
            "%02hhx"
        case .uppercase:
            "%02hhX"
        }
        return digest.map { String(format: format, $0) }.joined()
        #else
        // The demo package compiles without forcing a CryptoKit dependency on unsupported platforms.
        return nil
        #endif
    }
}
