/// Plain-card fields LiqPay accepts only against sandbox credentials, for testing a `pay` charge
/// without a real payment instrument (e.g. Apple Pay).
public struct LiqPaySandboxCard: Sendable, Equatable {
    public var number: String
    public var expMonth: String
    public var expYear: String
    public var cvv: String

    public init(number: String, expMonth: String, expYear: String, cvv: String) {
        self.number = number
        self.expMonth = expMonth
        self.expYear = expYear
        self.cvv = cvv
    }
}
