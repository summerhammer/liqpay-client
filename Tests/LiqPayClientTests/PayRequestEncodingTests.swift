import Foundation
@testable import LiqPayClient
import Testing

@Suite("PayRequest encoding")
struct PayRequestEncodingTests {
    private func encodeToJSONObject(_ request: PayRequest) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test func encodesRequiredFieldsUnderUpstreamKeyNames() throws {
        let request = PayRequest(
            version: 3,
            publicKey: PublicKey("sandbox_test_public_key"),
            amount: 550,
            currency: "UAH",
            description: "Membership",
            orderId: OrderId("order-123")
        )
        let json = try encodeToJSONObject(request)

        #expect(json["version"] as? Int == 3)
        #expect(json["action"] as? String == "pay")
        #expect(json["public_key"] as? String == "sandbox_test_public_key")
        #expect(json["amount"] as? Double == 550)
        #expect(json["currency"] as? String == "UAH")
        #expect(json["description"] as? String == "Membership")
        #expect(json["order_id"] as? String == "order-123")
    }

    @Test func omitsOptionalFieldsEntirelyWhenNil() throws {
        let request = PayRequest(
            version: 3,
            publicKey: PublicKey("sandbox_test_public_key"),
            amount: 550,
            currency: "UAH",
            description: "Membership",
            orderId: OrderId("order-123")
        )
        let json = try encodeToJSONObject(request)

        #expect(json["paytype"] == nil)
        #expect(json["applepay_token"] == nil)
        #expect(json["server_url"] == nil)
        #expect(json["language"] == nil)
        #expect(json["card"] == nil)
        #expect(json["card_exp_month"] == nil)
        #expect(json["card_exp_year"] == nil)
        #expect(json["card_cvv"] == nil)
        #expect(json["rro_info"] == nil)
    }

    @Test func encodesApplePayFields() throws {
        let request = PayRequest(
            version: 3,
            publicKey: PublicKey("sandbox_test_public_key"),
            amount: 550,
            currency: "UAH",
            description: "Membership",
            orderId: OrderId("order-123"),
            paytype: "apay",
            applePayToken: "base64-payment-data",
            serverURL: URL(string: "https://example.com/liqpay/callback"),
            language: "uk"
        )
        let json = try encodeToJSONObject(request)

        #expect(json["paytype"] as? String == "apay")
        #expect(json["applepay_token"] as? String == "base64-payment-data")
        #expect(json["server_url"] as? String == "https://example.com/liqpay/callback")
        #expect(json["language"] as? String == "uk")
    }

    @Test func flattensSandboxCardFieldsOntoTopLevel() throws {
        let request = PayRequest(
            version: 3,
            publicKey: PublicKey("sandbox_test_public_key"),
            amount: 550,
            currency: "UAH",
            description: "Membership",
            orderId: OrderId("order-123"),
            card: LiqPaySandboxCard(number: "4242424242424242", expMonth: "12", expYear: "30", cvv: "123")
        )
        let json = try encodeToJSONObject(request)

        #expect(json["card"] as? String == "4242424242424242")
        #expect(json["card_exp_month"] as? String == "12")
        #expect(json["card_exp_year"] as? String == "30")
        #expect(json["card_cvv"] as? String == "123")
    }

    @Test func encodesRROInfoAsNestedObject() throws {
        let request = PayRequest(
            version: 3,
            publicKey: PublicKey("sandbox_test_public_key"),
            amount: 550,
            currency: "UAH",
            description: "Membership",
            orderId: OrderId("order-123"),
            rroInfo: TestFactories.rroInfo()
        )
        let json = try encodeToJSONObject(request)

        let rroInfo = try #require(json["rro_info"] as? [String: Any])
        let deliveryEmails = try #require(rroInfo["delivery_emails"] as? [String])
        #expect(deliveryEmails == ["client@example.com"])

        let items = try #require(rroInfo["items"] as? [[String: Any]])
        #expect(items.count == 1)

        let item = items[0]
        #expect(item["amount"] as? NSNumber == NSNumber(value: 2.0))
        #expect(item["price"] as? NSNumber == NSNumber(value: 100.5))
        #expect(item["cost"] as? NSNumber == NSNumber(value: 201.0))
        #expect(item["id"] as? Int == 12345)
    }

    @Test func omitsNilFieldsInsideRROInfo() throws {
        let requestWithItemsOnly = PayRequest(
            version: 3,
            publicKey: PublicKey("sandbox_test_public_key"),
            amount: 550,
            currency: "UAH",
            description: "Membership",
            orderId: OrderId("order-123"),
            rroInfo: TestFactories.rroInfo(deliveryEmails: nil)
        )
        let jsonWithItemsOnly = try encodeToJSONObject(requestWithItemsOnly)
        let rroInfoWithItemsOnly = try #require(jsonWithItemsOnly["rro_info"] as? [String: Any])
        #expect(rroInfoWithItemsOnly["items"] != nil)
        #expect(rroInfoWithItemsOnly["delivery_emails"] == nil)

        let requestWithEmailsOnly = PayRequest(
            version: 3,
            publicKey: PublicKey("sandbox_test_public_key"),
            amount: 550,
            currency: "UAH",
            description: "Membership",
            orderId: OrderId("order-123"),
            rroInfo: TestFactories.rroInfo(items: nil)
        )
        let jsonWithEmailsOnly = try encodeToJSONObject(requestWithEmailsOnly)
        let rroInfoWithEmailsOnly = try #require(jsonWithEmailsOnly["rro_info"] as? [String: Any])
        #expect(rroInfoWithEmailsOnly["delivery_emails"] != nil)
        #expect(rroInfoWithEmailsOnly["items"] == nil)
    }
}
