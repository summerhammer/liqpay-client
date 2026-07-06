import Foundation

extension Client {
    /// `client.webhooks` — verify and decode signed `server_url` callback payloads.
    public struct Webhooks: Sendable {
        let client: Client

        /// Verifies `signature` against `data` using the configured private key, then decodes the
        /// payload. Purely local — never touches the transport.
        public func decode(data: String, signature: String) throws(LiqPayClientError) -> LiqPayResponse {
            let privateKey = client.credentials.privateKey
            guard LiqPaySigner.verify(privateKey: privateKey, data: data, signature: signature) else {
                throw .invalidSignature
            }
            guard let payload = Data(base64Encoded: data) else {
                throw .invalidPayloadEncoding
            }
            do {
                return try JSONDecoder().decode(LiqPayResponse.self, from: payload)
            } catch {
                let preview = String(bytes: payload.prefix(512), encoding: .utf8) ?? "<non-UTF8 body>"
                throw .decodingFailed(underlying: error, bodyPreview: preview)
            }
        }
    }

    public var webhooks: Webhooks { Webhooks(client: self) }
}
