@testable import LiqPayClient
@testable import LiqPayClientVapor
import Testing
import Vapor

private struct DummyError: Error {}

@Suite("LiqPayClientError AbortError mapping")
struct AbortErrorMappingTests {
    @Test func invalidSignatureMapsToUnauthorized() {
        #expect(LiqPayClientError.invalidSignature.status == .unauthorized)
    }

    @Test func invalidPayloadEncodingMapsToBadRequest() {
        #expect(LiqPayClientError.invalidPayloadEncoding.status == .badRequest)
    }

    @Test func notConfiguredMapsToInternalServerError() {
        #expect(LiqPayClientError.notConfigured(reason: "missing keys").status == .internalServerError)
    }

    @Test func transportFailureMapsToBadGateway() {
        #expect(LiqPayClientError.transportFailure(underlying: DummyError()).status == .badGateway)
    }

    @Test func decodingFailedMapsToBadGateway() {
        #expect(LiqPayClientError.decodingFailed(underlying: DummyError(), bodyPreview: "").status == .badGateway)
    }

    @Test func encodingFailedMapsToInternalServerError() {
        #expect(LiqPayClientError.encodingFailed(underlying: DummyError()).status == .internalServerError)
    }

    @Test func unexpectedMapsToInternalServerError() {
        #expect(LiqPayClientError.unexpected(DummyError()).status == .internalServerError)
    }
}
