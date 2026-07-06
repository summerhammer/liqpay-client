import Foundation

/// Builds the `data` half of a LiqPay request envelope: sorted-key JSON, base64-encoded.
///
/// Keys must be sorted because the resulting base64 string is itself the thing that gets signed
/// (see ``LiqPaySigner``) — encoding the same payload twice must always produce the same `data`
/// string, which `JSONEncoder`'s default key ordering does not guarantee.
enum LiqPayEnvelopeEncoder {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    static func encode(_ payload: some Encodable) throws -> String {
        try encoder.encode(payload).base64EncodedString()
    }
}
