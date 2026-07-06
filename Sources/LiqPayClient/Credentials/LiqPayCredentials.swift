/// The merchant credential pair every LiqPay action is signed/authenticated with.
public struct LiqPayCredentials: Sendable {
    public let publicKey: PublicKey
    public let privateKey: PrivateKey

    public init(publicKey: PublicKey, privateKey: PrivateKey) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }

    /// LiqPay's own convention: sandbox merchant credentials are issued with a `sandbox_` prefix
    /// on the public key. There is no separate sandbox/production flag in LiqPay's API.
    public var isSandbox: Bool { publicKey.isSandbox }
}
