import Foundation
@testable import LiqPayClient

/// Records the last request it was asked to send and returns a stubbed response/error.
///
/// An `actor` here is a deliberate exception to "struct everywhere, actor only for genuinely
/// shared mutable state" — recording mutable last-call state across `async` calls under Swift 6
/// strict concurrency is exactly that case.
actor MockTransport: LiqPayTransport {
    private(set) var lastRequest: LiqPayTransportRequest?
    var stubbedResponse = LiqPayTransportResponse(statusCode: 200, body: Data("{}".utf8))
    var stubbedError: (any Error)?

    func send(_ request: LiqPayTransportRequest) async throws -> LiqPayTransportResponse {
        lastRequest = request
        if let stubbedError { throw stubbedError }
        return stubbedResponse
    }

    func setStubbedResponse(_ response: LiqPayTransportResponse) {
        stubbedResponse = response
    }

    func setStubbedError(_ error: any Error) {
        stubbedError = error
    }
}
