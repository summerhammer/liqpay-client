import Foundation
@testable import LiqPayClient
@testable import LiqPayClientVapor
import Testing
import VaporTesting

private struct UnusedTransport: LiqPayTransport {
    func send(_ request: LiqPayTransportRequest) async throws -> LiqPayTransportResponse {
        fatalError("registerLiqPayWebhook's handler never touches the transport")
    }
}

private actor CapturedCallback {
    private(set) var orderId: String?
    func record(_ orderId: String?) {
        self.orderId = orderId
    }
}

@Suite("registerLiqPayWebhook")
struct WebhookRouteTests {
    private static let privateKey = PrivateKey("test_private_key")

    private static func makeClient() -> LiqPayClient.Client {
        LiqPayClient.Client(
            credentials: LiqPayCredentials(publicKey: PublicKey("sandbox_test_public_key"), privateKey: privateKey),
            transport: UnusedTransport()
        )
    }

    private static func signedEnvelope(json: String) -> (data: String, signature: String) {
        let data = Data(json.utf8).base64EncodedString()
        let signature = LiqPaySigner.sign(privateKey: privateKey, data: data)
        return (data, signature)
    }

    @Test func returns200AndInvokesHandlerForAValidCallback() async throws {
        let client = Self.makeClient()
        let envelope = Self.signedEnvelope(json: #"{"order_id":"order-123","status":"success"}"#)
        let captured = CapturedCallback()

        try await withApp { app in
            app.registerLiqPayWebhook("liqpay", "callback", client: client) { response, _ in
                await captured.record(response.orderId?.rawValue)
            }

            try await app.testing().test(.POST, "liqpay/callback", beforeRequest: { req in
                try req.content.encode(
                    ["data": envelope.data, "signature": envelope.signature],
                    as: .urlEncodedForm
                )
            }, afterResponse: { res async in
                #expect(res.status == .ok)
            })
        }

        #expect(await captured.orderId == "order-123")
    }

    @Test func returns401ForATamperedSignature() async throws {
        let client = Self.makeClient()
        let envelope = Self.signedEnvelope(json: #"{"order_id":"order-123","status":"success"}"#)

        try await withApp { app in
            app.registerLiqPayWebhook("liqpay", "callback", client: client) { _, _ in }

            try await app.testing().test(.POST, "liqpay/callback", beforeRequest: { req in
                try req.content.encode(
                    ["data": envelope.data, "signature": "tampered-signature"],
                    as: .urlEncodedForm
                )
            }, afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }

    @Test func returns400ForAnUndecodablePayload() async throws {
        let client = Self.makeClient()
        let garbage = "not valid base64!!!"
        let signature = LiqPaySigner.sign(privateKey: Self.privateKey, data: garbage)

        try await withApp { app in
            app.registerLiqPayWebhook("liqpay", "callback", client: client) { _, _ in }

            try await app.testing().test(.POST, "liqpay/callback", beforeRequest: { req in
                try req.content.encode(["data": garbage, "signature": signature], as: .urlEncodedForm)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
}
