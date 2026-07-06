import Foundation
import LiqPayClient
import Vapor

/// A ``LiqPayTransport`` implementation backed by Vapor's `Client` (typically `app.client` or
/// `request.client`).
public struct LiqPayVaporTransport: LiqPayTransport {
    let client: Vapor.Client

    public init(client: Vapor.Client) {
        self.client = client
    }

    public func send(_ request: LiqPayTransportRequest) async throws -> LiqPayTransportResponse {
        let response = try await client.post(URI(string: request.endpoint.absoluteString)) { clientRequest in
            try clientRequest.content.encode(
                ["data": request.data, "signature": request.signature],
                as: .urlEncodedForm
            )
        }
        var buffer = response.body
        let readableBytes = buffer?.readableBytes ?? 0
        let bytes = buffer?.readData(length: readableBytes) ?? Data()
        return LiqPayTransportResponse(statusCode: Int(response.status.code), body: bytes)
    }
}
