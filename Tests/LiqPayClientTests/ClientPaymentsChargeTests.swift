import Foundation
@testable import LiqPayClient
import Testing

@Suite("Client.payments.charge")
struct ClientPaymentsChargeTests {
    @Test func sendsASignedPayRequestWithExpectedFields() async throws {
        let transport = MockTransport()
        let client = TestFactories.client(transport: transport)

        _ = try await client.payments.charge(
            amount: 550,
            currency: "UAH",
            description: "Membership",
            orderId: TestFactories.orderId()
        )

        let sentRequest = try #require(await transport.lastRequest)
        #expect(sentRequest.endpoint == LiqPayConfiguration.defaultEndpoint)

        let decodedData = try #require(Data(base64Encoded: sentRequest.data))
        let json = try #require(try JSONSerialization.jsonObject(with: decodedData) as? [String: Any])
        #expect(json["action"] as? String == "pay")
        #expect(json["public_key"] as? String == "sandbox_test_public_key")
        #expect(json["order_id"] as? String == "order-123")
        #expect(json["amount"] as? Double == 550)
        #expect(json["currency"] as? String == "UAH")

        #expect(LiqPaySigner.verify(
            privateKey: TestFactories.privateKey(),
            data: sentRequest.data,
            signature: sentRequest.signature
        ))
    }

    @Test func fallsBackToConfiguredCallbackURLAndLanguage() async throws {
        let transport = MockTransport()
        let client = TestFactories.client(
            transport: transport,
            configuration: TestFactories.configuration(
                callbackURL: URL(string: "https://example.com/liqpay/callback")
            )
        )

        _ = try await client.payments.charge(
            amount: 550, currency: "UAH", description: "Membership", orderId: TestFactories.orderId()
        )

        let sentRequest = try #require(await transport.lastRequest)
        let decodedData = try #require(Data(base64Encoded: sentRequest.data))
        let json = try #require(try JSONSerialization.jsonObject(with: decodedData) as? [String: Any])
        #expect(json["server_url"] as? String == "https://example.com/liqpay/callback")
    }

    @Test func decodesSuccessfulResponseIntoOutcome() async throws {
        let transport = MockTransport()
        await setStubbedResponse(on: transport, body: TestFactories.responseBody(status: "sandbox"))
        let client = TestFactories.client(transport: transport)

        let response = try await client.payments.charge(
            amount: 550, currency: "UAH", description: "Membership", orderId: TestFactories.orderId()
        )

        #expect(response.outcome == .succeeded(isSandbox: true))
        #expect(response.orderId == TestFactories.orderId())
    }

    @Test func passesRROInfoThroughToSignedPayload() async throws {
        let transport = MockTransport()
        let client = TestFactories.client(transport: transport)

        _ = try await client.payments.charge(
            amount: 550,
            currency: "UAH",
            description: "Membership",
            orderId: TestFactories.orderId(),
            rroInfo: TestFactories.rroInfo()
        )

        let sentRequest = try #require(await transport.lastRequest)
        let decodedData = try #require(Data(base64Encoded: sentRequest.data))
        let json = try #require(try JSONSerialization.jsonObject(with: decodedData) as? [String: Any])

        let rroInfo = try #require(json["rro_info"] as? [String: Any])
        let deliveryEmails = try #require(rroInfo["delivery_emails"] as? [String])
        #expect(deliveryEmails == ["client@example.com"])

        let items = try #require(rroInfo["items"] as? [[String: Any]])
        #expect(items.count == 1)
        #expect(items[0]["id"] as? Int == 12345)

        #expect(LiqPaySigner.verify(
            privateKey: TestFactories.privateKey(),
            data: sentRequest.data,
            signature: sentRequest.signature
        ))
    }

    @Test func passesGooglePayTokenThroughToSignedPayload() async throws {
        let transport = MockTransport()
        let client = TestFactories.client(transport: transport)

        let tokenJSON = """
        {"protocolVersion":"ECv2","signature":"abc","signedMessage":"..."}
        """
        let googlePayToken = LiqPayGooglePayToken(tokenJSON: tokenJSON)

        _ = try await client.payments.charge(
            amount: 550,
            currency: "UAH",
            description: "Membership",
            orderId: TestFactories.orderId(),
            paytype: "gpay",
            googlePayToken: googlePayToken
        )

        let sentRequest = try #require(await transport.lastRequest)
        let decodedData = try #require(Data(base64Encoded: sentRequest.data))
        let json = try #require(try JSONSerialization.jsonObject(with: decodedData) as? [String: Any])

        #expect(json["paytype"] as? String == "gpay")

        let expectedBase64 = Data(tokenJSON.utf8).base64EncodedString()
        #expect(json["gpay_token"] as? String == expectedBase64)

        #expect(LiqPaySigner.verify(
            privateKey: TestFactories.privateKey(),
            data: sentRequest.data,
            signature: sentRequest.signature
        ))
    }

}

private func setStubbedResponse(on transport: MockTransport, body: Data) async {
    await transport.setStubbedResponse(LiqPayTransportResponse(statusCode: 200, body: body))
}
