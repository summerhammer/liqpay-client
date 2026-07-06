import LiqPayClient
import Vapor

/// The `application/x-www-form-urlencoded` body LiqPay POSTs to a `server_url` callback.
struct LiqPayWebhookPayload: Content {
    let data: String
    let signature: String
}

extension RoutesBuilder {
    /// Registers a POST route at `path` that decodes, verifies, and dispatches a LiqPay webhook
    /// callback. Thrown ``LiqPayClientError``s (invalid signature, undecodable payload) propagate
    /// through Vapor's `AbortError` machinery to the status mapped in `LiqPayClientError+AbortError`.
    @discardableResult
    public func registerLiqPayWebhook(
        _ path: PathComponent...,
        client: LiqPayClient.Client,
        handler: @escaping @Sendable (LiqPayResponse, Request) async throws -> Void
    ) -> Route {
        self.on(.POST, path) { request async throws -> HTTPStatus in
            let payload = try request.content.decode(LiqPayWebhookPayload.self)
            let response = try client.webhooks.decode(data: payload.data, signature: payload.signature)
            try await handler(response, request)
            return .ok
        }
    }
}
