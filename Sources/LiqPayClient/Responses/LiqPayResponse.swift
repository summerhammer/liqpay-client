/// The payload LiqPay returns from a synchronous `api/request` call, and also the payload decoded
/// from a signed `server_url` webhook callback — both share this exact shape.
public struct LiqPayResponse: Decodable, Sendable {
    public let result: String?
    public let status: String?
    public let action: String?
    public let paytype: String?
    public let orderId: OrderId?
    public let liqpayOrderId: String?
    public let paymentId: Int64?
    public let transactionId: Int64?
    public let amount: Double?
    public let currency: String?
    public let errCode: String?
    public let errDescription: String?
    /// Some LiqPay error responses carry the error under `code` instead of `err_code`.
    public let code: String?

    enum CodingKeys: String, CodingKey {
        case result, status, action, paytype, amount, currency, code
        case orderId = "order_id"
        case liqpayOrderId = "liqpay_order_id"
        case paymentId = "payment_id"
        case transactionId = "transaction_id"
        case errCode = "err_code"
        case errDescription = "err_description"
    }

    public init(
        result: String? = nil,
        status: String? = nil,
        action: String? = nil,
        paytype: String? = nil,
        orderId: OrderId? = nil,
        liqpayOrderId: String? = nil,
        paymentId: Int64? = nil,
        transactionId: Int64? = nil,
        amount: Double? = nil,
        currency: String? = nil,
        errCode: String? = nil,
        errDescription: String? = nil,
        code: String? = nil
    ) {
        self.result = result
        self.status = status
        self.action = action
        self.paytype = paytype
        self.orderId = orderId
        self.liqpayOrderId = liqpayOrderId
        self.paymentId = paymentId
        self.transactionId = transactionId
        self.amount = amount
        self.currency = currency
        self.errCode = errCode
        self.errDescription = errDescription
        self.code = code
    }
}
