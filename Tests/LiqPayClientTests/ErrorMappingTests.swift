import Foundation
@testable import LiqPayClient
import Testing

/// Covers `Client.perform`'s error mapping in general (independent of any one action) — see
/// `ClientPaymentsChargeTests`/`ClientPaymentsStatusTests` for action-specific field/signing
/// behavior, and `WebhookDecodingTests` for the local (non-transport) signature/decoding errors.
@Suite("Client error mapping")
struct ErrorMappingTests {
    private struct BoomError: Error {}

    @Test func transportFailurePreservesUnderlyingError() async throws {
        let transport = MockTransport()
        await transport.setStubbedError(BoomError())
        let client = TestFactories.client(transport: transport)

        do {
            _ = try await client.payments.status(orderId: TestFactories.orderId())
            Issue.record("Expected status to throw")
        } catch {
            guard case .transportFailure(let underlying) = error else {
                Issue.record("Expected .transportFailure, got \(error)")
                return
            }
            #expect(underlying is BoomError)
        }
    }

    @Test func malformedResponseBodyBecomesDecodingFailedWithPreview() async throws {
        let transport = MockTransport()
        let body = Data("this is not json".utf8)
        await transport.setStubbedResponse(LiqPayTransportResponse(statusCode: 200, body: body))
        let client = TestFactories.client(transport: transport)

        do {
            _ = try await client.payments.status(orderId: TestFactories.orderId())
            Issue.record("Expected status to throw")
        } catch {
            guard case .decodingFailed(_, let bodyPreview) = error else {
                Issue.record("Expected .decodingFailed, got \(error)")
                return
            }
            #expect(bodyPreview == "this is not json")
        }
    }
}
