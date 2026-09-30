import Foundation
import Testing
@testable import Pango

@Suite("Private resource access", .serialized)
struct PangolinPrivateResourceAccessServiceTests {
    private func makeService() throws -> PangolinPrivateResourceAccessService {
        let session = URLSessionConfiguration.ephemeral
        session.protocolClasses = [URLProtocolStub.self]
        return PangolinPrivateResourceAccessService(client: PangolinAPIClient(
            configuration: try PangolinAPIConfiguration(baseURLString: "https://api.example.com", apiKey: "synthetic-key"),
            session: URLSession(configuration: session)
        ))
    }

    @Test("loads the exact assignment endpoint", arguments: PrivateResourceAccessKind.allCases)
    func loadsAssignments(kind: PrivateResourceAccessKind) async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/private-resource/7/\(kind.rawValue)")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            let data: String
            switch kind {
            case .users: data = #"{"users":[{"userId":"u1","email":"test+access@example.com","username":null}]}"#
            case .roles: data = #"{"roles":[{"roleId":1,"name":"Admin","isAdmin":true},{"roleId":2,"name":"Reader","isAdmin":false}]}"#
            case .clients: data = #"{"clients":[{"clientId":3,"name":null,"subnet":"100.1.2.3/32"}]}"#
            }
            return .init(statusCode: 200, data: Self.envelope(data))
        }
        let options = try await makeService().listAssignments(resourceId: 7, kind: kind)
        switch kind {
        case .users: #expect(options == [.init(id: "u1", name: "test+access@example.com")])
        case .roles: #expect(options == [.init(id: "1", name: "Admin", isReadOnly: true), .init(id: "2", name: "Reader")])
        case .clients: #expect(options == [.init(id: "3", name: "100.1.2.3/32")])
        }
    }

    @Test("sends only the selected assignment category", arguments: PrivateResourceAccessKind.allCases, [false, true])
    func savesAssignments(kind: PrivateResourceAccessKind, clear: Bool) async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/private-resource/7/\(kind.rawValue)")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-key")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            switch kind {
            case .users:
                #expect(Set(json.keys) == ["userIds"])
                #expect(json["userIds"] as? [String] == (clear ? [] : ["3"]))
            case .roles:
                #expect(Set(json.keys) == ["roleIds"])
                #expect(json["roleIds"] as? [Int] == (clear ? [] : [3]))
            case .clients:
                #expect(Set(json.keys) == ["clientIds"])
                #expect(json["clientIds"] as? [Int] == (clear ? [] : [3]))
            }
            return .init(statusCode: 200, data: Self.envelope("null"))
        }
        try await makeService().setAssignments(resourceId: 7, kind: kind, ids: clear ? [] : ["3"])
    }

    @Test("rejects missing assignment data rather than treating it as empty", arguments: PrivateResourceAccessKind.allCases)
    func rejectsMissingData(kind: PrivateResourceAccessKind) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Self.envelope("null")) }
        await #expect(throws: PangolinAPIError.decoding) {
            try await makeService().listAssignments(resourceId: 7, kind: kind)
        }
    }

    @Test("preserves permission failures for reads and writes", arguments: PrivateResourceAccessKind.allCases, [false, true])
    func rejectsForbidden(kind: PrivateResourceAccessKind, write: Bool) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 403, data: Data()) }
        await #expect(throws: PangolinAPIError.forbidden) {
            if write { try await makeService().setAssignments(resourceId: 7, kind: kind, ids: []) }
            else { _ = try await makeService().listAssignments(resourceId: 7, kind: kind) }
        }
    }

    @Test("rejects unsuccessful envelopes", arguments: PrivateResourceAccessKind.allCases, [false, true])
    func rejectsEnvelope(kind: PrivateResourceAccessKind, write: Bool) async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 200, data: Data(#"{"data":null,"success":false,"error":true,"message":"rejected","status":400}"#.utf8)) }
        await #expect(throws: PangolinAPIError.serverRejected(status: 400, message: "rejected")) {
            if write { try await makeService().setAssignments(resourceId: 7, kind: kind, ids: []) }
            else { _ = try await makeService().listAssignments(resourceId: 7, kind: kind) }
        }
    }

    @Test("does not send malformed numeric IDs", arguments: [PrivateResourceAccessKind.roles, .clients])
    func rejectsInvalidIDs(kind: PrivateResourceAccessKind) async throws {
        URLProtocolStub.handler = { _ in
            Issue.record("Invalid selection must not send a request")
            return .init(statusCode: 200, data: Self.envelope("{}"))
        }
        await #expect(throws: PangolinAPIError.decoding) {
            try await makeService().setAssignments(resourceId: 7, kind: kind, ids: ["invalid"])
        }
    }

    @Test("preserves unavailable assigned entries and protects administrator roles")
    func preservesSelection() {
        var selection = PrivateResourceAccessSelection(
            assigned: [.init(id: "1", name: "Admin", isReadOnly: true), .init(id: "2", name: "Unavailable")],
            available: [.init(id: "1", name: "Admin", isReadOnly: true), .init(id: "3", name: "Reader")]
        )
        #expect(selection.options.map(\.id) == ["1", "2", "3"])
        selection.toggle(id: "1")
        selection.toggle(id: "3")
        #expect(selection.selectedIDs == ["1", "2", "3"])
        #expect(selection.editableIDs == ["2", "3"])
        selection.toggle(id: "2")
        #expect(selection.editableIDs == ["3"])
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
