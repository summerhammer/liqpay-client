# LiqPayClient

A server-side Swift client for the [LiqPay](https://www.liqpay.ua) payment platform. Built for
Linux (Swift on Server) as well as Darwin — no Apple-only APIs.

## Features

- `pay` (charge) and `status` actions, with LiqPay's status vocabulary already classified into a
  simple succeeded/pending/failed outcome
- Apple Pay and Google Pay wallet charges (`applepay_token` / `gpay_token` on `pay`)
- Signed webhook (`server_url` callback) verification and decoding
- Transport-agnostic core — bring your own HTTP client, or use the bundled Vapor transport
- Namespaced API: `client.payments.charge(...)`, `client.payments.status(...)`, `client.webhooks.decode(...)`

See [ENDPOINTS.md](ENDPOINTS.md) for the full LiqPay action coverage checklist.

## Installation

```swift
.package(url: "https://github.com/<org>/liqpay-client.git", from: "0.1.0")
```

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "LiqPayClient", package: "liqpay-client"),
    // Only needed if you're on Vapor:
    .product(name: "LiqPayClientVapor", package: "liqpay-client"),
])
```

## Quick Start

### Without Vapor

`LiqPayClient` only needs something that implements ``LiqPayTransport`` — a single-method protocol,
since LiqPay's whole API is one endpoint. Here it is with bare `URLSession`:

```swift
import LiqPayClient
import FoundationNetworking // Linux only

struct URLSessionTransport: LiqPayTransport {
    func send(_ request: LiqPayTransportRequest) async throws -> LiqPayTransportResponse {
        var urlRequest = URLRequest(url: request.endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = Data("data=\(request.data)&signature=\(request.signature)".utf8)

        let (body, response) = try await URLSession.shared.data(for: urlRequest)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        return LiqPayTransportResponse(statusCode: statusCode, body: body)
    }
}

let client = LiqPayClient.Client(
    credentials: LiqPayCredentials(
        publicKey: PublicKey("sandbox_..."),
        privateKey: PrivateKey("...")
    ),
    transport: URLSessionTransport()
)
```

### With Vapor

```swift
import LiqPayClient
import LiqPayClientVapor
import Vapor

let client = LiqPayClient.Client(
    credentials: LiqPayCredentials(
        publicKey: PublicKey(Environment.get("LIQPAY_PUBLIC_KEY")!),
        privateKey: PrivateKey(Environment.get("LIQPAY_PRIVATE_KEY")!)
    ),
    configuration: LiqPayConfiguration(
        callbackURL: URL(string: "https://example.com/liqpay/callback")
    ),
    transport: LiqPayVaporTransport(client: app.client)
)
```

## Usage

```swift
let response = try await client.payments.charge(
    amount: 550,
    currency: "UAH",
    description: "Membership",
    orderId: OrderId("order-123")
)

switch response.outcome {
case .succeeded(let isSandbox):
    // finalize the order (isSandbox lets you flag test charges separately)
    break
case .pending:
    // poll client.payments.status(orderId:) or wait for the webhook callback
    break
case .failed(let code, let message):
    // show the decline reason to the user
    break
}
```

Fiscalization (ПРРО):

```swift
let response = try await client.payments.charge(
    amount: 250,
    currency: "UAH",
    description: "Coffee",
    orderId: OrderId("order-456"),
    rroInfo: LiqPayRROInfo(
        items: [.init(amount: 1, price: 250, cost: 250, id: 12345)],
        deliveryEmails: ["customer@example.com"]
    )
)
```

Google Pay (encrypted-token flow — LiqPay decrypts the token, no PCI DSS needed):

```swift
// `tokenJSON` is the string your Android/web app got from Google:
// paymentData.paymentMethodData.tokenizationData.token — forward it verbatim, do not parse it.
let response = try await client.payments.charge(
    amount: 550,
    currency: "UAH",
    description: "Membership",
    orderId: OrderId("order-789"),
    paytype: "gpay",
    googlePayToken: LiqPayGooglePayToken(tokenJSON: tokenJSON)
)
```

`LiqPayGooglePayToken(tokenJSON:)` does the base64 encoding LiqPay requires; if the app already
sent it base64-encoded, use `LiqPayGooglePayToken(base64:)` instead. On the app side, configure
Google Pay's `PAYMENT_GATEWAY` tokenization with `gateway: "liqpay"` and `gatewayMerchantId: <your
LiqPay public_key>`, card networks `MASTERCARD`/`VISA`, auth methods `PAN_ONLY`/`CRYPTOGRAM_3DS`.
A `3ds_verify` status in the response means LiqPay wants a 3-D Secure confirmation step, which
this client does not yet model.

Apple Pay works the same way with `paytype: "apay"` and `applePayToken:` (the base64
`paymentData` from the Apple Pay token).

Querying status directly:

```swift
let response = try await client.payments.status(orderId: OrderId("order-123"))
```

Registering the webhook route (Vapor):

```swift
app.registerLiqPayWebhook("liqpay", "callback", client: client) { response, request in
    switch response.outcome {
    case .succeeded, .pending, .failed:
        // update your order/payment record; LiqPayClientError thrown here maps to an
        // appropriate HTTP status automatically (see Error Handling below)
        break
    }
}
```

Decoding a webhook payload yourself (non-Vapor):

```swift
let response = try client.webhooks.decode(data: formFields["data"]!, signature: formFields["signature"]!)
```

## Architecture

`LiqPayClient` (core) owns all LiqPay domain logic — signing, request/response models, status
classification — behind a single transport protocol. `LiqPayClientVapor` supplies a concrete
transport and webhook route helper; nothing Vapor-specific leaks into core.

| Concern | Extension point | Shipped today |
|---|---|---|
| HTTP transport | `LiqPayTransport` protocol | `LiqPayClientVapor` (Vapor's `Client`) |
| A LiqPay action not yet wrapped in a facade method | `LiqPayAction` protocol + `.execute(using:)` | `PayRequest`, `StatusRequest` |
| Webhook framework integration | route-registration helper | Vapor only |

> **Note:** both `Vapor` and `LiqPayClient` export a type named `Client`. When both modules are
> imported in the same file, qualify as `Vapor.Client` / `LiqPayClient.Client`.

## Configuration

| Setting | Where | Notes |
|---|---|---|
| `publicKey` / `privateKey` | `LiqPayCredentials` | Required. Sandbox is detected automatically from a `sandbox_` prefix on the public key — there's no separate sandbox flag. |
| `endpoint` | `LiqPayConfiguration` | Defaults to `https://www.liqpay.ua/api/request`. |
| `callbackURL` | `LiqPayConfiguration` | Sent as `server_url` on `pay`; omit to rely solely on the synchronous response. |
| `defaultLanguage` | `LiqPayConfiguration` | Sent as `language` when a call doesn't override it. |

A typical Vapor app loads credentials from `LIQPAY_PUBLIC_KEY`/`LIQPAY_PRIVATE_KEY` environment
variables and a callback URL from `LIQPAY_CALLBACK_URL`; this package doesn't read environment
variables itself, since env var names/conventions are an application concern.

## Error Handling

Every throwing API in this package uses typed throws (`throws(LiqPayClientError)`). `LiqPayClientVapor`
conforms `LiqPayClientError` to Vapor's `AbortError`, so a thrown error inside a
`registerLiqPayWebhook` handler is reported with a sensible status automatically:

| Case | HTTP status |
|---|---|
| `.invalidSignature` | 401 Unauthorized |
| `.invalidPayloadEncoding` | 400 Bad Request |
| `.transportFailure`, `.decodingFailed` | 502 Bad Gateway |
| `.notConfigured`, `.encodingFailed`, `.unexpected` | 500 Internal Server Error |

## Testing

Tests use [swift-testing](https://github.com/apple/swift-testing) (`@Test`/`#expect`), not XCTest.

```sh
swift test
```

`Tests/LiqPayClientTests/Support/MockTransport.swift` and `TestFactories.swift` are a good starting
point if you want to test your own code against this client without hitting the network.

## Requirements

- Swift 6.3+
- Linux or Darwin
