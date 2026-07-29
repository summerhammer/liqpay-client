import Foundation
@testable import LiqPayClient
import Testing

@Suite("Client.webhooks.decode")
struct WebhookDecodingTests {
    private static let privateKey = TestFactories.privateKey()

    private static func makeClient() -> Client {
        TestFactories.client(
            transport: MockTransport(),
            credentials: TestFactories.credentials(privateKey: privateKey)
        )
    }

    private static func signedEnvelope(json: String) -> (data: String, signature: String) {
        let data = Data(json.utf8).base64EncodedString()
        let signature = LiqPaySigner.sign(privateKey: privateKey, data: data)
        return (data, signature)
    }

    @Test func decodesAValidlySignedCallback() throws {
        let envelope = Self.signedEnvelope(
            json: #"{"order_id":"order-123","status":"sandbox","payment_id":12345,"amount":1500,"currency":"UAH"}"#
        )

        let response = try Self.makeClient().webhooks.decode(data: envelope.data, signature: envelope.signature)

        #expect(response.orderId == OrderId("order-123"))
        #expect(response.outcome == .succeeded(isSandbox: true))
        #expect(response.paymentId == 12345)
        #expect(response.rroReceiptStatus == nil)
        #expect(response.rroErrDescription == nil)
    }

    @Test func decodesFiscalizationFieldsWhenPresent() throws {
        let envelope = Self.signedEnvelope(
            json: #"{"order_id":"order-123","status":"success","rro_receipt_status":"failure","rro_err_description":"Не вдалося провести фіскалізацію платежу."}"#
        )

        let response = try Self.makeClient().webhooks.decode(data: envelope.data, signature: envelope.signature)

        #expect(response.rroReceiptStatus == "failure")
        #expect(response.rroErrDescription == "Не вдалося провести фіскалізацію платежу.")
    }

    @Test func throwsInvalidSignatureForTamperedSignature() {
        let envelope = Self.signedEnvelope(json: #"{"order_id":"order-123","status":"sandbox"}"#)
        var tamperedSignature = envelope.signature
        tamperedSignature.removeLast()
        tamperedSignature.append(tamperedSignature.last == "A" ? "B" : "A")

        do {
            _ = try Self.makeClient().webhooks.decode(data: envelope.data, signature: tamperedSignature)
            Issue.record("Expected decode to throw")
        } catch {
            guard case .invalidSignature = error else {
                Issue.record("Expected .invalidSignature, got \(error)")
                return
            }
        }
    }

    @Test func throwsInvalidPayloadEncodingForNonBase64Data() {
        let garbage = "not valid base64!!!"
        let signature = LiqPaySigner.sign(privateKey: Self.privateKey, data: garbage)

        do {
            _ = try Self.makeClient().webhooks.decode(data: garbage, signature: signature)
            Issue.record("Expected decode to throw")
        } catch {
            guard case .invalidPayloadEncoding = error else {
                Issue.record("Expected .invalidPayloadEncoding, got \(error)")
                return
            }
        }
    }

    @Test func throwsDecodingFailedForValidBase64ThatIsNotJSON() {
        let notJSON = Data("this is not json".utf8).base64EncodedString()
        let signature = LiqPaySigner.sign(privateKey: Self.privateKey, data: notJSON)

        do {
            _ = try Self.makeClient().webhooks.decode(data: notJSON, signature: signature)
            Issue.record("Expected decode to throw")
        } catch {
            guard case .decodingFailed(_, let bodyPreview) = error else {
                Issue.record("Expected .decodingFailed, got \(error)")
                return
            }
            #expect(bodyPreview == "this is not json")
        }
    }
}
