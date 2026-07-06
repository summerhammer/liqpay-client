/// The `action=status` wire payload — queries the current state of a previously-created order.
public struct StatusRequest: LiqPayAction {
    public static let action = "status"

    public var version: Int
    public var publicKey: PublicKey
    public var orderId: OrderId

    public init(version: Int, publicKey: PublicKey, orderId: OrderId) {
        self.version = version
        self.publicKey = publicKey
        self.orderId = orderId
    }

    private enum CodingKeys: String, CodingKey {
        case version, action
        case publicKey = "public_key"
        case orderId = "order_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(Self.action, forKey: .action)
        try container.encode(publicKey, forKey: .publicKey)
        try container.encode(orderId, forKey: .orderId)
    }
}
