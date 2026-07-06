/// LiqPay's `public_key` credential.
///
/// Wrapped rather than passed as a bare `String` so call sites can't accidentally swap it with a
/// ``PrivateKey`` or an ``OrderId``.
public struct PublicKey: LosslessStringConvertible, Hashable, Sendable {
    public let rawValue: String

    // A nonfailable initializer is a valid conformance to `LosslessStringConvertible`'s
    // `init?(_:)` requirement (Swift allows nonfailable inits to satisfy failable requirements),
    // so there's no separate optional-returning initializer to declare here.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }

    /// LiqPay's own convention: sandbox merchant credentials are issued with a `sandbox_` prefix
    /// on the public key. There is no separate sandbox/production flag in LiqPay's API.
    public var isSandbox: Bool {
        rawValue.hasPrefix("sandbox_")
    }
}

extension PublicKey: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension PublicKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
