import Foundation
import Testing
@testable import Pango

@Suite("Pangolin API client", .serialized)
struct PangolinAPIClientTests {
    private struct Payload: Codable, Equatable {
        let value: String
    }

    private func makeClient() throws -> PangolinAPIClient {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolStub.self]
        return PangolinAPIClient(
            configuration: try PangolinAPIConfiguration(
                baseURLString: "https://api.example.com/v1/",
                apiKey: "synthetic-key"
            ),
            session: URLSession(configuration: sessionConfiguration)
        )
    }

    @Test("constructs an authenticated request with encoded query items")
    func constructsRequest() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/orgs?email=person%2Btest%40example.com")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == nil)
            return .init(
                statusCode: 200,
                data: Data(#"{"data":{"value":"ok"},"success":true,"error":false,"message":"","status":200}"#.utf8)
            )
        }

        let response: PangolinResponse<Payload> = try await makeClient().send(
            .get,
            path: "/orgs",
            queryItems: [URLQueryItem(name: "email", value: "person+test@example.com")]
        )

        #expect(response.data == Payload(value: "ok"))
    }

    @Test("encodes a JSON body")
    func encodesJSONBody() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.httpMethod == "PATCH")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let body = try #require(request.bodyData)
            #expect(try JSONDecoder().decode(Payload.self, from: body) == Payload(value: "changed"))
            return .init(
                statusCode: 200,
                data: Data(#"{"success":true,"error":false,"message":"Saved","status":200}"#.utf8)
            )
        }

        let response: PangolinResponse<PangolinEmptyResponse> = try await makeClient().send(
            .patch,
            path: "/resource/1",
            body: Payload(value: "changed")
        )

        #expect(response.success)
    }

    @Test(
        "maps authentication and capability statuses",
        arguments: [
            (401, PangolinAPIError.unauthenticated),
            (403, PangolinAPIError.forbidden),
            (404, PangolinAPIError.unsupported),
            (405, PangolinAPIError.unsupported),
            (500, PangolinAPIError.httpFailure(status: 500))
        ]
    )
    func mapsHTTPStatus(statusCode: Int, expectedError: PangolinAPIError) async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: statusCode, data: Data())
        }

        await #expect(throws: expectedError) {
            let _: PangolinResponse<PangolinEmptyResponse> = try await makeClient().send(.get, path: "/orgs")
        }
    }

    @Test("preserves a Pangolin validation rejection")
    func preservesValidationRejection() async throws {
        URLProtocolStub.handler = { _ in
            .init(
                statusCode: 422,
                data: Data(#"{"success":false,"error":true,"message":"Synthetic rejection","status":422}"#.utf8)
            )
        }

        await #expect(throws: PangolinAPIError.serverRejected(status: 422, message: "Synthetic rejection")) {
            let _: PangolinResponse<PangolinEmptyResponse> = try await makeClient().send(.post, path: "/resource/1")
        }
    }

    @Test("maps malformed JSON without exposing the key")
    func mapsMalformedJSON() async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: 200, data: Data("not-json".utf8))
        }

        do {
            let _: PangolinResponse<PangolinEmptyResponse> = try await makeClient().send(.get, path: "/orgs")
            Issue.record("Expected decoding to fail")
        } catch let error as PangolinAPIError {
            #expect(error == .decoding)
            #expect(!String(describing: error).contains("synthetic-key"))
        }
    }

    @Test("maps transport failures")
    func mapsTransportFailure() async throws {
        URLProtocolStub.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        await #expect(throws: PangolinAPIError.transport) {
            let _: PangolinResponse<PangolinEmptyResponse> = try await makeClient().send(.get, path: "/orgs")
        }
    }
}

private extension URLRequest {
    var bodyData: Data? {
        if let httpBody {
            return httpBody
        }
        guard let httpBodyStream else {
            return nil
        }
        httpBodyStream.open()
        defer { httpBodyStream.close() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1_024)
        defer { buffer.deallocate() }
        while httpBodyStream.hasBytesAvailable {
            let count = httpBodyStream.read(buffer, maxLength: 1_024)
            guard count > 0 else {
                break
            }
            data.append(buffer, count: count)
        }
        return data
    }
}
