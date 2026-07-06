/// LiqPay's `private_key` credential, used to sign outgoing requests and verify incoming webhooks.
///
/// Wrapped rather than passed as a bare `String` so call sites can't accidentally swap it with a
/// ``PublicKey`` or an ``OrderId``.
public struct PrivateKey: LosslessStringConvertible, Hashable, Sendable {
    public let rawValue: String

    // A nonfailable initializer is a valid conformance to `LosslessStringConvertible`'s
    // `init?(_:)` requirement (Swift allows nonfailable inits to satisfy failable requirements),
    // so there's no separate optional-returning initializer to declare here.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }
}

extension PrivateKey: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension PrivateKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
