import Foundation
import Testing
@testable import Pango

@Suite("Pangolin alert rule service", .serialized)
struct PangolinAlertRuleServiceTests {
    private func makeService() throws -> PangolinAlertRuleService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinAlertRuleService(
            client: PangolinAPIClient(
                configuration: try PangolinAPIConfiguration(baseURLString: "https://api.example.com", apiKey: "synthetic-key"),
                session: URLSession(configuration: configuration)
            ), organizationId: "synthetic-org"
        )
    }

    @Test("lists alert rules using the existing contract")
    func listsAlertRules() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/org/synthetic-org/alerts")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            #expect(request.bodyData == nil)
            return .init(statusCode: 200, data: Self.envelope(#"{"alerts":[{"alertId":7,"name":"Down","triggerType":"site_down","notificationMethod":"email","notificationTarget":"test@example.com","enabled":true},{"alertId":8,"name":"Future","triggerType":"new_event","notificationMethod":"new_method","notificationTarget":"synthetic-target","enabled":false}]}"#))
        }
        let alerts = try await makeService().listAlertRules()
        #expect(alerts.map(\.alertId) == [7, 8])
        #expect(alerts.map(\.name) == ["Down", "Future"])
        #expect(alerts.map(\.triggerType) == ["site_down", "new_event"])
        #expect(alerts.map(\.notificationMethod) == ["email", "new_method"])
        #expect(alerts.map(\.notificationTarget) == ["test@example.com", "synthetic-target"])
        #expect(alerts.map(\.enabled) == [true, false])
    }

    @Test("preserves empty and null alert lists", arguments: ["null", #"{"alerts":[]}"#])
    func listsEmptyAlerts(data: String) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Self.envelope(data)) }
        let alerts = try await makeService().listAlertRules()
        #expect(alerts.isEmpty)
    }

    @Test("creates an alert with only the existing fields", arguments: ["null", #"{"alertId":7}"#])
    func createsAlert(data: String) async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/org/synthetic-org/alert")
            #expect(request.httpMethod == "PUT")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
            #expect(json == ["name": "Service \"Down\"", "triggerType": "health_check_fail", "notificationMethod": "webhook", "notificationTarget": "https://hooks.example.com/alerts?a=1&b=2"])
            return .init(statusCode: 201, data: Self.envelope(data))
        }
        try await makeService().createAlertRule(name: "Service \"Down\"", triggerType: "health_check_fail", notificationMethod: "webhook", notificationTarget: "https://hooks.example.com/alerts?a=1&b=2")
    }

    @Test("deletes an alert without a body", arguments: ["null", "{}"])
    func deletesAlert(data: String) async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/org/synthetic-org/alert/7")
            #expect(request.httpMethod == "DELETE")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            #expect(request.bodyData == nil)
            return .init(statusCode: 200, data: Self.envelope(data))
        }
        try await makeService().deleteAlertRule(alertId: 7)
    }

    @Test("alert operations reject failed envelopes", arguments: Operation.allCases, [
        #"{"data":null,"success":false,"error":false,"message":"rejected","status":400}"#,
        #"{"data":null,"success":true,"error":true,"message":"rejected","status":400}"#
    ])
    func rejectsFailedEnvelope(operation: Operation, envelope: String) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Data(envelope.utf8)) }
        await #expect(throws: PangolinAPIError.serverRejected(status: 400, message: "rejected")) {
            try await perform(operation)
        }
    }

    @Test("alert operations preserve HTTP errors", arguments: Operation.allCases, [401, 403, 422])
    func preservesHTTPErrors(operation: Operation, status: Int) async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: status, data: Data(#"{"data":null,"success":false,"error":true,"message":"rejected","status":422}"#.utf8))
        }
        let expected: PangolinAPIError = status == 401 ? .unauthenticated
            : status == 403 ? .forbidden : .serverRejected(status: 422, message: "rejected")
        await #expect(throws: expected) { try await perform(operation) }
    }

    @Test("alert operations reject malformed responses", arguments: Operation.allCases)
    func rejectsMalformedResponse(operation: Operation) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Data("invalid".utf8)) }
        await #expect(throws: PangolinAPIError.decoding) { try await perform(operation) }
    }

    enum Operation: CaseIterable, Sendable { case list, create, delete }

    private func perform(_ operation: Operation) async throws {
        let service = try makeService()
        switch operation {
        case .list: _ = try await service.listAlertRules()
        case .create: try await service.createAlertRule(name: "Down", triggerType: "site_down", notificationMethod: "email", notificationTarget: "test@example.com")
        case .delete: try await service.deleteAlertRule(alertId: 7)
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
