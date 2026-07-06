import Foundation
@testable import LiqPayClient
import Testing

@Suite("StatusRequest encoding")
struct StatusRequestEncodingTests {
    @Test func encodesFieldsUnderUpstreamKeyNames() throws {
        let request = StatusRequest(
            version: 3,
            publicKey: PublicKey("sandbox_test_public_key"),
            orderId: OrderId("order-123")
        )
        let data = try JSONEncoder().encode(request)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["version"] as? Int == 3)
        #expect(json["action"] as? String == "status")
        #expect(json["public_key"] as? String == "sandbox_test_public_key")
        #expect(json["order_id"] as? String == "order-123")
        #expect(json.count == 4)
    }
}
