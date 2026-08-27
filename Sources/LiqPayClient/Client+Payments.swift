import Foundation

extension Client {
    /// `client.payments` — charge and query payments.
    public struct Payments: Sendable {
        let client: Client

        /// Charges `amount` of `currency` against `orderId` (LiqPay's `action=pay`).
        public func charge(
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
        ) async throws(LiqPayClientError) -> LiqPayResponse {
            let request = PayRequest(
                version: Client.apiVersion,
                publicKey: client.credentials.publicKey,
                amount: amount,
                currency: currency,
                description: description,
                orderId: orderId,
                paytype: paytype,
                applePayToken: applePayToken,
                googlePayToken: googlePayToken,
                card: card,
                rroInfo: rroInfo,
                serverURL: serverURL ?? client.configuration.callbackURL,
                language: language ?? client.configuration.defaultLanguage
            )
            return try await client.perform(request)
        }

        /// Queries the current state of a previously-created order (LiqPay's `action=status`).
        public func status(orderId: OrderId) async throws(LiqPayClientError) -> LiqPayResponse {
            let request = StatusRequest(
                version: Client.apiVersion,
                publicKey: client.credentials.publicKey,
                orderId: orderId
            )
            return try await client.perform(request)
        }
    }

    public var payments: Payments { Payments(client: self) }
}
