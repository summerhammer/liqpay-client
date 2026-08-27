import Foundation
@testable import LiqPayClient
import Testing

@Suite("LiqPayGooglePayToken")
struct GooglePayTokenTests {
    @Test func initWithTokenJSONBase64Encodes() throws {
        let tokenJSON = """
        {"signature":"abc","protocolVersion":"ECv2","signedMessage":"..."}
        """
        let token = LiqPayGooglePayToken(tokenJSON: tokenJSON)

        let expectedBase64 = Data(tokenJSON.utf8).base64EncodedString()
        #expect(token.base64 == expectedBase64)

        // Verify it decodes back to the original string
        let decodedData = try #require(Data(base64Encoded: token.base64))
        let decodedString = try #require(String(data: decodedData, encoding: .utf8))
        #expect(decodedString == tokenJSON)
    }

    @Test func initWithBase64StoresVerbatim() throws {
        let base64Token = "base64-encoded-token-value"
        let token = LiqPayGooglePayToken(base64: base64Token)

        #expect(token.base64 == base64Token)
    }

    @Test func encodesAsPlainString() throws {
        let token = LiqPayGooglePayToken(base64: "base64-token")
        let data = try JSONEncoder().encode(token)
        let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)

        // Should encode as a plain string, not an object
        #expect(json as? String == "base64-token")
    }

    @Test func equatableComparison() throws {
        let token1 = LiqPayGooglePayToken(base64: "same-base64")
        let token2 = LiqPayGooglePayToken(base64: "same-base64")
        let token3 = LiqPayGooglePayToken(base64: "different-base64")

        #expect(token1 == token2)
        #expect(token1 != token3)
    }
}
