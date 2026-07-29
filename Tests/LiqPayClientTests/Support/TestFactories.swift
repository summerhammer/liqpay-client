import Foundation
@testable import LiqPayClient

/// `.make()`-style static factories with sensible defaults, so tests only override what they
/// actually care about.
enum TestFactories {
    static func publicKey(_ raw: String = "sandbox_test_public_key") -> PublicKey {
        PublicKey(raw)
    }

    static func privateKey(_ raw: String = "test_private_key") -> PrivateKey {
        PrivateKey(raw)
    }

    static func orderId(_ raw: String = "order-123") -> OrderId {
        OrderId(raw)
    }

    static func credentials(
        publicKey: PublicKey = TestFactories.publicKey(),
        privateKey: PrivateKey = TestFactories.privateKey()
    ) -> LiqPayCredentials {
        LiqPayCredentials(publicKey: publicKey, privateKey: privateKey)
    }

    static func configuration(
        endpoint: URL = LiqPayConfiguration.defaultEndpoint,
        callbackURL: URL? = nil
    ) -> LiqPayConfiguration {
        LiqPayConfiguration(endpoint: endpoint, callbackURL: callbackURL)
    }

    static func client(
        transport: any LiqPayTransport,
        credentials: LiqPayCredentials = TestFactories.credentials(),
        configuration: LiqPayConfiguration = TestFactories.configuration()
    ) -> Client {
        Client(credentials: credentials, configuration: configuration, transport: transport)
    }

    /// A canned `pay`/`status` response body, for stubbing a ``MockTransport``.
    static func responseBody(
        status: String = "success",
        orderId: String = "order-123",
        paymentId: Int64 = 1,
        amount: Double = 550
    ) -> Data {
        let json = """
        {"result":"ok","status":"\(status)","order_id":"\(orderId)","payment_id":\(paymentId),"amount":\(amount)}
        """
        return Data(json.utf8)
    }

    static func rroInfo(
        items: [LiqPayRROInfo.Item]? = [.init(amount: 2, price: 100.5, cost: 201, id: 12345)],
        deliveryEmails: [String]? = ["client@example.com"]
    ) -> LiqPayRROInfo {
        LiqPayRROInfo(items: items, deliveryEmails: deliveryEmails)
    }
}
