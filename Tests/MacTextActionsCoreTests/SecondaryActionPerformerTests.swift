import XCTest
@testable import MacTextActionsCore

final class SecondaryActionPerformerTests: XCTestCase {
    func testCompressesJSONIntoSingleLineOutput() {
        let input = """
        {
          "name": "MacTextActions",
          "enabled": true
        }
        """

        let result = SecondaryActionPerformer.compressedJSON(from: input)

        XCTAssertEqual(result, "{\"enabled\":true,\"name\":\"MacTextActions\"}")
    }

    #if canImport(CryptoKit)
    func testGeneratesMD5HexDigest() {
        let result = SecondaryActionPerformer.md5Hex(for: "hello")

        XCTAssertEqual(result, "5d41402abc4b2a76b9719d911017c592")
    }
    #endif
}
