import Foundation
import Logging

/// The entry point for talking to LiqPay. Exposes nested, on-demand facades for each feature area
/// (`.payments`, `.webhooks`) rather than a flat method list.
///
/// `Client` itself never performs I/O — it holds credentials/configuration and delegates to the
/// injected ``LiqPayTransport`` for everything network-related, so it stays testable and
/// transport-agnostic (see `LiqPayClientVapor` for the Vapor-backed transport).
public struct Client: Sendable {
    /// The LiqPay API version sent as the `version` field on every action.
    static let apiVersion = 3

    public let credentials: LiqPayCredentials
    public var configuration: LiqPayConfiguration
    public var logger: Logger
    let transport: any LiqPayTransport

    public init(
        credentials: LiqPayCredentials,
        configuration: LiqPayConfiguration = LiqPayConfiguration(),
        transport: any LiqPayTransport,
        logger: Logger = Logger(label: "liqpay-client")
    ) {
        self.credentials = credentials
        self.configuration = configuration
        self.transport = transport
        self.logger = logger
    }

    /// Signs, sends, and decodes `action` against LiqPay. Reached via `.payments`/`.webhooks`, or
    /// directly through `LiqPayAction.execute(using:)` for actions not yet wrapped in a facade.
    func perform<Action: LiqPayAction>(_ action: Action) async throws(LiqPayClientError) -> Action.Response {
        let data: String
        do {
            data = try LiqPayEnvelopeEncoder.encode(action)
        } catch {
            throw .encodingFailed(underlying: error)
        }

        let signature = LiqPaySigner.sign(privateKey: credentials.privateKey, data: data)
        let request = LiqPayTransportRequest(endpoint: configuration.endpoint, data: data, signature: signature)

        let response: LiqPayTransportResponse
        do {
            response = try await transport.send(request)
        } catch {
            throw .transportFailure(underlying: error)
        }

        do {
            return try JSONDecoder().decode(Action.Response.self, from: response.body)
        } catch {
            let preview = String(bytes: response.body.prefix(512), encoding: .utf8) ?? "<non-UTF8 body>"
            throw .decodingFailed(underlying: error, bodyPreview: preview)
        }
    }
}
