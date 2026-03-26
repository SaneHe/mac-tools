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

    public static func md5Hex(for input: String) -> String? {
        #if canImport(CryptoKit)
        let digest = Insecure.MD5.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02hhx", $0) }.joined()
        #else
        // The demo package compiles without forcing a CryptoKit dependency on unsupported platforms.
        return nil
        #endif
    }
}
