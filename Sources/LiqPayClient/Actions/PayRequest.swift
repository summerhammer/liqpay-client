import Foundation

/// The `action=pay` wire payload — charges `amount` of `currency` against `orderId`.
public struct PayRequest: LiqPayAction {
    public static let action = "pay"

    public var version: Int
    public var publicKey: PublicKey
    public var amount: Decimal
    public var currency: String
    public var description: String
    public var orderId: OrderId
    /// e.g. `"apay"` for Apple Pay.
    public var paytype: String?
    /// Base64 Apple Pay payment data. Unwrapping a full ApplePayJS token down to just this inner
    /// `paymentData` is an application-side concern and out of scope for this package.
    public var applePayToken: String?
    /// Google Pay payment token (`gpay_token`); pair with `paytype: "gpay"`.
    public var googlePayToken: LiqPayGooglePayToken?
    /// Sandbox-only plain-card testing path.
    public var card: LiqPaySandboxCard?
    /// ПРРО fiscalization payload (`rro_info`).
    public var rroInfo: LiqPayRROInfo?
    /// Webhook callback URL LiqPay should POST the result to (`server_url`).
    public var serverURL: URL?
    public var language: String?

    public init(
        version: Int,
        publicKey: PublicKey,
        amount: Decimal,
        currency: String,
        description: String,
        orderId: OrderId,
        paytype: String? = nil,
        applePayToken: String? = nil,
        googlePayToken: LiqPayGooglePayToken? = nil,
        card: LiqPaySandboxCard? = nil,
        rroInfo: LiqPayRROInfo? = nil,
        serverURL: URL? = nil,
        language: String? = nil
    ) {
        self.version = version
        self.publicKey = publicKey
        self.amount = amount
        self.currency = currency
        self.description = description
        self.orderId = orderId
        self.paytype = paytype
        self.applePayToken = applePayToken
        self.googlePayToken = googlePayToken
        self.card = card
        self.rroInfo = rroInfo
        self.serverURL = serverURL
        self.language = language
    }

    private enum CodingKeys: String, CodingKey {
        case version, action, amount, currency, description, paytype, language
        case publicKey = "public_key"
        case orderId = "order_id"
        case applePayToken = "applepay_token"
        case googlePayToken = "gpay_token"
        case serverURL = "server_url"
        case card
        case cardExpMonth = "card_exp_month"
        case cardExpYear = "card_exp_year"
        case cardCvv = "card_cvv"
        case rroInfo = "rro_info"
    }

    // Manual encode(to:) because LiqPay expects the sandbox card's fields flattened onto the
    // top-level payload (card_exp_month/card_exp_year/card_cvv), not nested under "card".
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(Self.action, forKey: .action)
        try container.encode(publicKey, forKey: .publicKey)
        try container.encode(amount, forKey: .amount)
        try container.encode(currency, forKey: .currency)
        try container.encode(description, forKey: .description)
        try container.encode(orderId, forKey: .orderId)
        try container.encodeIfPresent(paytype, forKey: .paytype)
        try container.encodeIfPresent(applePayToken, forKey: .applePayToken)
        try container.encodeIfPresent(googlePayToken, forKey: .googlePayToken)
        try container.encodeIfPresent(rroInfo, forKey: .rroInfo)
        try container.encodeIfPresent(serverURL, forKey: .serverURL)
        try container.encodeIfPresent(language, forKey: .language)
        if let card {
            try container.encode(card.number, forKey: .card)
            try container.encode(card.expMonth, forKey: .cardExpMonth)
            try container.encode(card.expYear, forKey: .cardExpYear)
            try container.encode(card.cvv, forKey: .cardCvv)
        }
    }
}
