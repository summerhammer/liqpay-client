import LiqPayClient
import Vapor

/// Maps ``LiqPayClientError`` to an HTTP response status, so a thrown error from
/// `registerLiqPayWebhook`'s handler (or any other `LiqPayClient` call in a route) is reported to
/// the client with a sensible status rather than a generic 500. Kept in this module only — core
/// stays free of any Vapor/`AbortError` dependency.
extension LiqPayClientError: AbortError {
    public var status: HTTPResponseStatus {
        switch self {
        case .invalidSignature:
            return .unauthorized
        case .invalidPayloadEncoding:
            return .badRequest
        case .notConfigured, .encodingFailed, .unexpected:
            return .internalServerError
        case .transportFailure, .decodingFailed:
            return .badGateway
        }
    }

    public var reason: String {
        switch self {
        case .notConfigured(let reason):
            return "LiqPay client not configured: \(reason)"
        case .encodingFailed:
            return "Failed to encode LiqPay request"
        case .transportFailure:
            return "Failed to reach LiqPay"
        case .decodingFailed:
            return "Failed to decode LiqPay response"
        case .invalidSignature:
            return "Invalid LiqPay webhook signature"
        case .invalidPayloadEncoding:
            return "Invalid LiqPay webhook payload encoding"
        case .unexpected:
            return "Unexpected LiqPay client error"
        }
    }
}
