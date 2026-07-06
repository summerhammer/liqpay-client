/// A LiqPay `action` — the single-endpoint equivalent of a REST resource. Each concrete action
/// (``PayRequest``, ``StatusRequest``, ...) models one LiqPay `action` value and its wire fields;
/// `Client.perform(_:)` signs, sends, and decodes it.
///
/// Conforming your own type to this protocol lets you call a LiqPay action this package doesn't
/// yet wrap in a nicer facade method, via `execute(using:)`, without forking the package.
public protocol LiqPayAction: Encodable, Sendable {
    associatedtype Response: Decodable & Sendable = LiqPayResponse
    /// The wire value of LiqPay's `action` field, e.g. `"pay"`.
    static var action: String { get }
}

extension LiqPayAction {
    /// Signs, sends, and decodes this action against `client` — the escape hatch mentioned above.
    public func execute(using client: Client) async throws(LiqPayClientError) -> Response {
        try await client.perform(self)
    }
}
