import Crypto
import Foundation

/// Implements LiqPay's request/callback signing scheme: `base64(SHA1(private_key + data + private_key))`.
///
/// Uses swift-crypto's `Insecure.SHA1` rather than Apple's CryptoKit, since this package must build
/// and run on Linux (Swift on Server) as well as Darwin. SHA-1 here is LiqPay's own protocol
/// requirement, not a choice made by this package — it is not used for anything security-sensitive
/// beyond matching LiqPay's fixed signing scheme.
public enum LiqPaySigner: Sendable {
    /// Computes the LiqPay signature for a given base64 `data` payload.
    public static func sign(privateKey: PrivateKey, data: String) -> String {
        let material = Data((privateKey.rawValue + data + privateKey.rawValue).utf8)
        let digest = Insecure.SHA1.hash(data: material)
        return Data(digest).base64EncodedString()
    }

    /// Verifies that `signature` matches the signature LiqPay would compute for `data` with
    /// `privateKey`. Used both to validate webhook callbacks and, in tests, to confirm outgoing
    /// requests were signed correctly.
    ///
    /// Compares the full byte sequences (after a length check) rather than short-circuiting on the
    /// first mismatching byte, to avoid leaking timing information about how much of the signature
    /// matched.
    public static func verify(privateKey: PrivateKey, data: String, signature: String) -> Bool {
        let expected = sign(privateKey: privateKey, data: data)
        guard expected.utf8.count == signature.utf8.count else { return false }
        var difference: UInt8 = 0
        for (lhs, rhs) in zip(expected.utf8, signature.utf8) {
            difference |= lhs ^ rhs
        }
        return difference == 0
    }
}
