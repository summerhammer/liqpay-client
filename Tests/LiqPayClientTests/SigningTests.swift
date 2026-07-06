import Foundation
@testable import LiqPayClient
import Testing

/// Fixture verified against `openssl` independently of this package's own implementation.
private struct SigningFixture: Encodable {
    let action = "pay"
    let amount = 550
    let currency = "UAH"
}

@Suite("LiqPay signing")
struct SigningTests {
    private static let privateKey = PrivateKey("test_private_key")
    private static let expectedData = "eyJhY3Rpb24iOiJwYXkiLCJhbW91bnQiOjU1MCwiY3VycmVuY3kiOiJVQUgifQ=="
    private static let expectedSignature = "H9g/sVid6hqh3bnLK6geMezwFCw="

    @Test func envelopeEncoderProducesSortedKeyBase64() throws {
        let data = try LiqPayEnvelopeEncoder.encode(SigningFixture())
        #expect(data == Self.expectedData)
    }

    @Test func signProducesTheVerifiedFixtureVector() {
        let signature = LiqPaySigner.sign(privateKey: Self.privateKey, data: Self.expectedData)
        #expect(signature == Self.expectedSignature)
    }

    @Test func verifyAcceptsMatchingSignature() {
        #expect(LiqPaySigner.verify(
            privateKey: Self.privateKey,
            data: Self.expectedData,
            signature: Self.expectedSignature
        ))
    }

    @Test func verifyRejectsTamperedSignature() {
        var tampered = Self.expectedSignature
        tampered.removeLast()
        tampered.append(tampered.last == "A" ? "B" : "A")
        #expect(!LiqPaySigner.verify(privateKey: Self.privateKey, data: Self.expectedData, signature: tampered))
    }

    @Test func verifyRejectsTamperedData() {
        let tamperedData = String(Self.expectedData.dropLast()) + "X"
        #expect(!LiqPaySigner.verify(
            privateKey: Self.privateKey,
            data: tamperedData,
            signature: Self.expectedSignature
        ))
    }

    @Test func verifyRejectsWrongPrivateKey() {
        #expect(!LiqPaySigner.verify(
            privateKey: PrivateKey("wrong_private_key"),
            data: Self.expectedData,
            signature: Self.expectedSignature
        ))
    }

    @Test func verifyRejectsDifferentLengthSignature() {
        #expect(!LiqPaySigner.verify(
            privateKey: Self.privateKey,
            data: Self.expectedData,
            signature: String(Self.expectedSignature.dropLast())
        ))
    }
}
