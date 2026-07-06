@testable import LiqPayClient
import Testing

@Suite("LiqPayResponse outcome classification")
struct OutcomeClassificationTests {
    private struct StatusCase: Sendable, CustomStringConvertible {
        let status: String?
        let errCode: String?
        let code: String?
        let expected: LiqPayOutcome

        var description: String { status ?? "nil" }
    }

    private static let statusCases: [StatusCase] = [
        StatusCase(status: "success", errCode: nil, code: nil, expected: .succeeded(isSandbox: false)),
        StatusCase(status: "wait_accept", errCode: nil, code: nil, expected: .succeeded(isSandbox: false)),
        StatusCase(status: "sandbox", errCode: nil, code: nil, expected: .succeeded(isSandbox: true)),
        StatusCase(status: "failure", errCode: "limit", code: nil, expected: .failed(code: "limit", message: nil)),
        StatusCase(status: "error", errCode: nil, code: "err_auth", expected: .failed(code: "err_auth", message: nil)),
        StatusCase(status: "processing", errCode: nil, code: nil, expected: .pending)
    ]

    @Test(arguments: statusCases)
    private func classifiesByStatus(_ testCase: StatusCase) {
        let response = LiqPayResponse(status: testCase.status, errCode: testCase.errCode, code: testCase.code)
        #expect(response.outcome == testCase.expected)
    }

    @Test func statusActionErrorWithNoStatusFieldIsFailed() {
        // Real-world shape: {"result":"ok","err_code":"shop_blocked"} — no "status" key at all.
        let response = LiqPayResponse(result: "ok", errCode: "shop_blocked")
        #expect(response.outcome == .failed(code: "shop_blocked", message: nil))
    }

    @Test func noStatusNoErrorCodeIsPending() {
        let response = LiqPayResponse(result: "ok")
        #expect(response.outcome == .pending)
    }

    @Test func errDescriptionIsCarriedThroughToFailedOutcome() {
        let response = LiqPayResponse(status: "failure", errCode: "limit", errDescription: "Payment limit exceeded")
        #expect(response.outcome == .failed(code: "limit", message: "Payment limit exceeded"))
    }

    @Test func codeIsUsedWhenErrCodeIsAbsent() {
        let response = LiqPayResponse(status: "error", code: "err_auth")
        #expect(response.outcome == .failed(code: "err_auth", message: nil))
    }
}
