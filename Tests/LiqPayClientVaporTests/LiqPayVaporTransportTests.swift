@testable import LiqPayClient
@testable import LiqPayClientVapor
import Testing
import Vapor

/// A minimal `Vapor.Client` double: records the last request it was asked to send and returns a
/// stubbed response, without touching the network.
private final class FakeVaporClient: Vapor.Client, @unchecked Sendable {
    let eventLoop: EventLoop
    private(set) var lastRequest: ClientRequest?
    var stubbedResponse: ClientResponse

    init(eventLoop: EventLoop, stubbedResponse: ClientResponse) {
        self.eventLoop = eventLoop
        self.stubbedResponse = stubbedResponse
    }

    func delegating(to eventLoop: EventLoop) -> Vapor.Client {
        self
    }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        lastRequest = request
        return eventLoop.makeSucceededFuture(stubbedResponse)
    }
}

@Suite("LiqPayVaporTransport")
struct LiqPayVaporTransportTests {
    @Test func sendsAFormEncodedPOSTToTheGivenEndpoint() async throws {
        let eventLoop = EmbeddedEventLoop()
        let fakeClient = FakeVaporClient(
            eventLoop: eventLoop,
            stubbedResponse: ClientResponse(status: .ok, body: ByteBuffer(string: "{}"))
        )
        let transport = LiqPayVaporTransport(client: fakeClient)

        _ = try await transport.send(LiqPayTransportRequest(
            endpoint: LiqPayConfiguration.defaultEndpoint,
            data: "base64-data",
            signature: "base64-signature"
        ))

        let sent = try #require(fakeClient.lastRequest)
        #expect(sent.method == .POST)
        #expect(sent.url.string == LiqPayConfiguration.defaultEndpoint.absoluteString)
        #expect(sent.headers.contentType == .urlEncodedForm)

        let bodyString = sent.body.map { String(buffer: $0) } ?? ""
        #expect(bodyString.contains("data=base64-data"))
        #expect(bodyString.contains("signature=base64-signature"))
    }

    @Test func mapsStatusCodeAndBodyFromTheClientResponse() async throws {
        let eventLoop = EmbeddedEventLoop()
        let fakeClient = FakeVaporClient(
            eventLoop: eventLoop,
            stubbedResponse: ClientResponse(status: .badGateway, body: ByteBuffer(string: #"{"result":"ok"}"#))
        )
        let transport = LiqPayVaporTransport(client: fakeClient)

        let response = try await transport.send(LiqPayTransportRequest(
            endpoint: LiqPayConfiguration.defaultEndpoint,
            data: "base64-data",
            signature: "base64-signature"
        ))

        #expect(response.statusCode == 502)
        #expect(String(bytes: response.body, encoding: .utf8) == #"{"result":"ok"}"#)
    }
}
