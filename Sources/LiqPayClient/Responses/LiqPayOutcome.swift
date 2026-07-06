/// The coarse-grained result of a LiqPay `pay`/`status` response, classified from LiqPay's raw
/// `status`/`result`/`err_code` fields so that no consumer of this package has to re-derive
/// LiqPay's status vocabulary itself.
public enum LiqPayOutcome: Sendable, Equatable {
    /// LiqPay considers the charge final and successful. `wait_accept` (funds held pending shop
    /// review) is documented by LiqPay itself as a success state and is folded in here.
    case succeeded(isSandbox: Bool)
    /// Not yet final — keep polling `status` or wait for the webhook callback.
    case pending
    /// LiqPay considers the charge final and failed, or the request itself was rejected.
    case failed(code: String?, message: String?)
}

extension LiqPayResponse {
    /// Classifies this response/callback payload into a ``LiqPayOutcome``.
    ///
    /// - `status` of `success` or `wait_accept` → `.succeeded(isSandbox: false)`
    /// - `status` of `sandbox` → `.succeeded(isSandbox: true)`
    /// - `status` of `failure` or `error` → `.failed`
    /// - no `status` at all but `err_code`/`code` is present (e.g. a `status`-action response like
    ///   `{"result":"ok","err_code":"shop_blocked"}`, which has no `status` field) → `.failed`
    /// - anything else → `.pending`
    ///
    /// Known limitation: a payment refunded out-of-band reports `status: "reversed"`, which falls
    /// through to `.pending` here — LiqPayClient doesn't implement the `refund` action yet, so
    /// there's no dedicated outcome case for it (tracked in ENDPOINTS.md).
    public var outcome: LiqPayOutcome {
        if let status {
            switch status {
            case "success", "wait_accept":
                return .succeeded(isSandbox: false)
            case "sandbox":
                return .succeeded(isSandbox: true)
            case "failure", "error":
                return .failed(code: errCode ?? code, message: errDescription)
            default:
                return .pending
            }
        }
        if errCode != nil || code != nil {
            return .failed(code: errCode ?? code, message: errDescription)
        }
        return .pending
    }
}
