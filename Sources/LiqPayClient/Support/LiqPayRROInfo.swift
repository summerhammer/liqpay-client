import Foundation

/// ПРРО (software fiscal registrar) fiscalization payload — LiqPay's `rro_info`.
/// Only UAH payments are fiscalized; LiqPay validates item data server-side.
public struct LiqPayRROInfo: Sendable, Equatable, Encodable {
    /// One fiscalized line item.
    public struct Item: Sendable, Equatable, Encodable {
        /// Quantity/volume of the good (fractional allowed).
        public var amount: Decimal
        /// Unit price.
        public var price: Decimal
        /// Total cost of the units (`amount` × `price`).
        public var cost: Decimal
        /// Goods ID from the merchant's LiqPay cabinet (СКР → Каса → Товари).
        public var id: Int

        public init(amount: Decimal, price: Decimal, cost: Decimal, id: Int) {
            self.amount = amount
            self.price = price
            self.cost = cost
            self.id = id
        }
    }

    /// Goods being paid for.
    public var items: [Item]?
    /// Emails the fiscal receipt is sent to after fiscalization.
    public var deliveryEmails: [String]?

    public init(items: [Item]? = nil, deliveryEmails: [String]? = nil) {
        self.items = items
        self.deliveryEmails = deliveryEmails
    }

    private enum CodingKeys: String, CodingKey {
        case items
        case deliveryEmails = "delivery_emails"
    }
}
