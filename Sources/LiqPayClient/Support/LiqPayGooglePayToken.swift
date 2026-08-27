import Foundation

/// LiqPay's `gpay_token` — the JSON string Google returns in
/// `paymentMethodData.tokenizationData.token`, base64-encoded as LiqPay expects.
public struct LiqPayGooglePayToken: Sendable, Equatable, Encodable {
    /// The base64 form that goes on the wire.
    public let base64: String

    /// Wraps an already-base64-encoded token.
    public init(base64: String) {
        self.base64 = base64
    }

    /// Base64-encodes the raw token JSON string from Google.
    public init(tokenJSON: String) {
        self.base64 = Data(tokenJSON.utf8).base64EncodedString()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(base64)
    }
}
