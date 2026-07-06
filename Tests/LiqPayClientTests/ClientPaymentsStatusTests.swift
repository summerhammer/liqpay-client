import Foundation
@testable import LiqPayClient
import Testing

@Suite("Client.payments.status")
struct ClientPaymentsStatusTests {
    @Test func sendsASignedStatusRequestWithExpectedFields() async throws {
        let transport = MockTransport()
        let client = TestFactories.client(transport: transport)

        _ = try await client.payments.status(orderId: TestFactories.orderId())

        let sentRequest = try #require(await transport.lastRequest)
        let decodedData = try #require(Data(base64Encoded: sentRequest.data))
        let json = try #require(try JSONSerialization.jsonObject(with: decodedData) as? [String: Any])
        #expect(json["action"] as? String == "status")
        #expect(json["order_id"] as? String == "order-123")
        #expect(json.count == 4)

        #expect(LiqPaySigner.verify(
            privateKey: TestFactories.privateKey(),
            data: sentRequest.data,
            signature: sentRequest.signature
        ))
    }

    @Test func classifiesShopBlockedStatusResponseAsFailed() async throws {
        let transport = MockTransport()
        let body = Data(#"{"result":"ok","err_code":"shop_blocked"}"#.utf8)
        await transport.setStubbedResponse(LiqPayTransportResponse(statusCode: 200, body: body))
        let client = TestFactories.client(transport: transport)

        let response = try await client.payments.status(orderId: TestFactories.orderId())

        #expect(response.outcome == .failed(code: "shop_blocked", message: nil))
    }
}
