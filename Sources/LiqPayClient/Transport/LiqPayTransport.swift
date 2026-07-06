import Foundation

/// A fully-built LiqPay request envelope, ready to POST as `application/x-www-form-urlencoded`.
public struct LiqPayTransportRequest: Sendable {
    public let endpoint: URL
    public let data: String
    public let signature: String

    public init(endpoint: URL, data: String, signature: String) {
        self.endpoint = endpoint
        self.data = data
        self.signature = signature
    }
}

/// The raw result of sending a ``LiqPayTransportRequest``.
public struct LiqPayTransportResponse: Sendable {
    /// Kept for diagnostics only — LiqPay returns HTTP 200 even for declined charges or invalid
    /// requests, so this must never be used to decide success/failure.
    public let statusCode: Int
    /// Raw response bytes. LiqPay's `Content-Type` header is not reliable, so callers must decode
    /// JSON from these bytes directly rather than trusting any declared content type.
    public let body: Data

    public init(statusCode: Int, body: Data) {
        self.statusCode = statusCode
        self.body = body
    }
}

/// The only seam between LiqPay's domain logic and HTTP. LiqPay's entire API is a single endpoint,
/// always POSTed, always form-encoded `{data, signature}` — so unlike a typical REST client this
/// needs just one method, not one per HTTP verb.
///
/// Implementations must not branch success/failure on `statusCode`: only genuine transport
/// failures (no connection, timeout, TLS, DNS, ...) should `throw` here. A declined charge or a
/// malformed-request error from LiqPay is still a "successful" transport call — it's surfaced to
/// callers through the decoded ``LiqPayResponse``'s `.outcome`, not as a thrown error.
public protocol LiqPayTransport: Sendable {
    func send(_ request: LiqPayTransportRequest) async throws -> LiqPayTransportResponse
}
