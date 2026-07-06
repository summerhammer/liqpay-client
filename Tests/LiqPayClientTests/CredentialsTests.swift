import Foundation
@testable import LiqPayClient
import Testing

@Suite("Credential wrapper types")
struct CredentialsTests {
    @Test func publicKeyRoundTripsThroughJSON() throws {
        let key = PublicKey("sandbox_test_public_key")
        let encoded = try JSONEncoder().encode(key)
        let decoded = try JSONDecoder().decode(PublicKey.self, from: encoded)
        #expect(decoded == key)
    }

    @Test func publicKeyDetectsSandboxPrefix() {
        #expect(PublicKey("sandbox_test_public_key").isSandbox)
        #expect(!PublicKey("live_public_key").isSandbox)
    }

    @Test func privateKeyRoundTripsThroughJSON() throws {
        let key = PrivateKey("test_private_key")
        let encoded = try JSONEncoder().encode(key)
        let decoded = try JSONDecoder().decode(PrivateKey.self, from: encoded)
        #expect(decoded == key)
    }

    @Test func orderIdRoundTripsThroughJSON() throws {
        let orderId = OrderId("order-123")
        let encoded = try JSONEncoder().encode(orderId)
        let decoded = try JSONDecoder().decode(OrderId.self, from: encoded)
        #expect(decoded == orderId)
    }

    @Test func wrapperTypesAreLosslessStringConvertible() {
        #expect(PublicKey("sandbox_test_public_key").description == "sandbox_test_public_key")
        #expect(PublicKey(String("sandbox_test_public_key")) == PublicKey("sandbox_test_public_key"))
    }
}
