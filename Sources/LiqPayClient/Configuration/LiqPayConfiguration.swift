import Foundation

/// Non-credential settings for a ``Client``.
public struct LiqPayConfiguration: Sendable {
    public static let defaultEndpoint = URL(string: "https://www.liqpay.ua/api/request")!

    /// The URL every action is POSTed to. Defaults to LiqPay's production endpoint.
    public var endpoint: URL
    /// The webhook URL LiqPay should POST results to (sent as `server_url` on `pay`), if any.
    public var callbackURL: URL?
    /// Default `language` sent with requests, if any (e.g. `"uk"`).
    public var defaultLanguage: String?

    public init(
        endpoint: URL = LiqPayConfiguration.defaultEndpoint,
        callbackURL: URL? = nil,
        defaultLanguage: String? = nil
    ) {
        self.endpoint = endpoint
        self.callbackURL = callbackURL
        self.defaultLanguage = defaultLanguage
    }
}
