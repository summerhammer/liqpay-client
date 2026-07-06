/// The single error type surfaced by every throwing API in this package (`throws(LiqPayClientError)`),
/// distinguishing configuration, transport, and protocol-level failures without needing separate
/// error types per layer.
public enum LiqPayClientError: Error, Sendable {
    /// Required credentials/configuration are missing.
    case notConfigured(reason: String)
    /// Encoding an outgoing action payload failed.
    case encodingFailed(underlying: any Error)
    /// The underlying `LiqPayTransport` threw — a network/connection-level failure, not a LiqPay
    /// API-level error (those are surfaced via a decoded ``LiqPayResponse``'s `.outcome`, since
    /// LiqPay always answers with HTTP 200 even for declined charges or invalid requests).
    case transportFailure(underlying: any Error)
    /// The response body could not be decoded into the expected type. `bodyPreview` is a truncated
    /// prefix of the raw response for diagnostics.
    case decodingFailed(underlying: any Error, bodyPreview: String)
    /// A webhook callback's signature did not match what was recomputed from its `data` and the
    /// configured private key.
    case invalidSignature
    /// A webhook callback's `data` field was not valid base64.
    case invalidPayloadEncoding
    /// Any other unexpected failure.
    case unexpected(any Error)
}
