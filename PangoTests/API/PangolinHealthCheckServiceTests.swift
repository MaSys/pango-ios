import Foundation
import Testing
@testable import Pango

@Suite("Pangolin health check service", .serialized)
struct PangolinHealthCheckServiceTests {
    private func makeService() throws -> PangolinHealthCheckService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinHealthCheckService(
            client: PangolinAPIClient(
                configuration: try PangolinAPIConfiguration(baseURLString: "https://api.example.com", apiKey: "synthetic-key"),
                session: URLSession(configuration: configuration)
            ), organizationId: "synthetic-org"
        )
    }

    @Test("lists health checks using the existing contract")
    func listsHealthChecks() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/org/synthetic-org/health-checks")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            #expect(request.bodyData == nil)
            return .init(statusCode: 200, data: Self.envelope(#"{"healthChecks":[{"healthCheckId":7,"name":"Web","type":"http","url":"https://example.com","interval":60,"status":"healthy"},{"healthCheckId":8,"name":"Database","type":"tcp","host":"db.example.com","port":5432,"interval":3600}]}"#))
        }
        let checks = try await makeService().listHealthChecks()
        #expect(checks.map(\.healthCheckId) == [7, 8])
        #expect(checks.map(\.name) == ["Web", "Database"])
        #expect(checks.map(\.type) == ["http", "tcp"])
        #expect(checks.map(\.url) == ["https://example.com", nil])
        #expect(checks.map(\.host) == [nil, "db.example.com"])
        #expect(checks.map(\.port) == [nil, 5432])
        #expect(checks.map(\.interval) == [60, 3600])
        #expect(checks.map(\.status) == ["healthy", nil])
    }

    @Test("preserves empty and null health check lists", arguments: ["null", #"{"healthChecks":[]}"#])
    func listsEmptyChecks(data: String) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Self.envelope(data)) }
        let healthChecks = try await makeService().listHealthChecks()
        #expect(healthChecks.isEmpty)
    }

    @Test("creates a health check with only the existing fields", arguments: ["null", #"{"healthCheckId":7}"#], [60, 3600])
    func createsCheck(data: String, interval: Int) async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/org/synthetic-org/health-check")
            #expect(request.httpMethod == "PUT")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: AnyHashable])
            #expect(json == ["name": "Web", "type": "http", "url": "https://example.com/health?a=1&b=2", "interval": interval])
            return .init(statusCode: 201, data: Self.envelope(data))
        }
        try await makeService().createHealthCheck(name: "Web", type: "http", url: "https://example.com/health?a=1&b=2", interval: interval)
    }

    @Test("deletes a health check without a body", arguments: ["null", "{}"])
    func deletesCheck(data: String) async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/org/synthetic-org/health-check/7")
            #expect(request.httpMethod == "DELETE")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            #expect(request.bodyData == nil)
            return .init(statusCode: 200, data: Self.envelope(data))
        }
        try await makeService().deleteHealthCheck(healthCheckId: 7)
    }

    @Test("health check operations reject failed envelopes", arguments: Operation.allCases, [
        #"{"data":null,"success":false,"error":false,"message":"rejected","status":400}"#,
        #"{"data":null,"success":true,"error":true,"message":"rejected","status":400}"#
    ])
    func rejectsFailedEnvelope(operation: Operation, envelope: String) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Data(envelope.utf8)) }
        await #expect(throws: PangolinAPIError.serverRejected(status: 400, message: "rejected")) {
            try await perform(operation)
        }
    }

    @Test("health check operations preserve HTTP errors", arguments: Operation.allCases, [401, 403, 422])
    func preservesHTTPErrors(operation: Operation, status: Int) async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: status, data: Data(#"{"data":null,"success":false,"error":true,"message":"rejected","status":422}"#.utf8))
        }
        let expected: PangolinAPIError = status == 401 ? .unauthenticated
            : status == 403 ? .forbidden : .serverRejected(status: 422, message: "rejected")
        await #expect(throws: expected) { try await perform(operation) }
    }

    @Test("health check operations reject malformed responses", arguments: Operation.allCases)
    func rejectsMalformedResponse(operation: Operation) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Data("invalid".utf8)) }
        await #expect(throws: PangolinAPIError.decoding) { try await perform(operation) }
    }

    enum Operation: CaseIterable, Sendable { case list, create, delete }

    private func perform(_ operation: Operation) async throws {
        let service = try makeService()
        switch operation {
        case .list: _ = try await service.listHealthChecks()
        case .create: try await service.createHealthCheck(name: "Database", type: "tcp", url: "db.example.com", interval: 60)
        case .delete: try await service.deleteHealthCheck(healthCheckId: 7)
        }
    }

    private static func envelope(_ data: String) -> Data {
        Data("{\"data\":\(data),\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }
}

private extension URLRequest {
    var bodyData: Data? {
        if let httpBody { return httpBody }
        guard let httpBodyStream else { return nil }
        httpBodyStream.open()
        defer { httpBodyStream.close() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1_024)
        defer { buffer.deallocate() }
        while httpBodyStream.hasBytesAvailable {
            let count = httpBodyStream.read(buffer, maxLength: 1_024)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
