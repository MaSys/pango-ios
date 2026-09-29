import Foundation
import Testing
@testable import Pango

@Suite("Pangolin roles", .serialized)
struct PangolinRoleServiceTests {
    private func service() throws -> PangolinRoleService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinRoleService(client: PangolinAPIClient(
            configuration: try PangolinAPIConfiguration(baseURLString: "https://api.example.com", apiKey: "synthetic-key"),
            session: URLSession(configuration: configuration)
        ), organizationId: "org-1")
    }

    @Test func listsEveryPage() async throws {
        URLProtocolStub.handler = { request in
            let url = try #require(request.url)
            #expect(url.path == "/v1/org/org-1/roles")
            let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
            #expect(query.first { $0.name == "pageSize" }?.value == "1")
            let page = try #require(query.first { $0.name == "page" }?.value)
            return .init(statusCode: 200, data: Self.response("{\"roles\":[{\"roleId\":\(page),\"name\":\"Role \(page)\"}],\"pagination\":{\"total\":2,\"page\":\(page),\"pageSize\":1}}"))
        }
        let roles = try await service().listAllRoles(pageSize: 1)
        #expect(roles.map(\.roleId) == [1, 2])
    }

    @Test func createsRole() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/org/org-1/role")
            #expect(request.httpMethod == "PUT")
            let body = try #require(request.roleBodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
            #expect(json == ["name": "Support", "description": "Team"])
            return .init(statusCode: 201, data: Self.response(#"{"roleId":7,"name":"Support"}"#))
        }
        let role = try await service().create(name: "Support", description: "Team")
        #expect(role.roleId == 7)
    }

    @Test func deletesWithTransferRole() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/role/7")
            #expect(request.httpMethod == "DELETE")
            let body = try #require(request.roleBodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Int])
            #expect(json == ["roleId": 8])
            return .init(statusCode: 200, data: Self.response("null"))
        }
        try await service().delete(roleId: 7, transferRoleId: 8)
    }

    @Test func rejectsNonAdvancingPagination() async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: 200, data: Self.response(#"{"roles":[{"roleId":1}],"pagination":{"total":3,"page":1,"pageSize":1}}"#))
        }
        await #expect(throws: PangolinAPIError.decoding) {
            try await service().listAllRoles(pageSize: 1)
        }
    }

    @Test func preservesDeletePermissionError() async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: 403, data: Data())
        }
        await #expect(throws: PangolinAPIError.forbidden) {
            try await service().delete(roleId: 7, transferRoleId: 8)
        }
    }

    private static func response(_ data: String) -> Data {
        Data("{\"data\":\(data),\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }
}

private extension URLRequest {
    var roleBodyData: Data? {
        if let httpBody { return httpBody }
        guard let httpBodyStream else { return nil }
        httpBodyStream.open()
        defer { httpBodyStream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while httpBodyStream.hasBytesAvailable {
            let count = httpBodyStream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(contentsOf: buffer.prefix(count))
        }
        return data
    }
}
