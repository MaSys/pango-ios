import Foundation
import Testing
@testable import Pango

@Suite("Pangolin users", .serialized)
struct PangolinUserServiceTests {
    private func service() throws -> PangolinUserService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinUserService(client: PangolinAPIClient(
            configuration: try PangolinAPIConfiguration(baseURLString: "https://api.example.com", apiKey: "synthetic-key"),
            session: URLSession(configuration: configuration)
        ), organizationId: "org-1")
    }

    @Test func fetchesAllPagesAndPreservesRoles() async throws {
        URLProtocolStub.handler = { request in
            let url = try #require(request.url)
            #expect(url.path == "/v1/org/org-1/users")
            let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
            #expect(query.first { $0.name == "pageSize" }?.value == "1")
            let page = try #require(query.first { $0.name == "page" }?.value)
            return .init(statusCode: 200, data: Self.response(page: page))
        }
        let users = try await service().listAllUsers(pageSize: 1)
        #expect(users.map(\.id) == ["user-1", "user-2"])
        #expect(users.first?.roleNames == "Support")
    }

    @Test func rejectsRepeatedPageMetadata() async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: 200, data: Self.response(page: "1", total: 3))
        }
        await #expect(throws: PangolinAPIError.decoding) {
            try await service().listAllUsers(pageSize: 1)
        }
    }

    @Test func preservesPermissionError() async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: 403, data: Data())
        }
        await #expect(throws: PangolinAPIError.forbidden) {
            try await service().listAllUsers()
        }
    }

    private static func response(page: String, total: Int = 2) -> Data {
        Data("{\"data\":{\"users\":[{\"id\":\"user-\(page)\",\"email\":\"person\(page)@example.com\",\"type\":\"internal\",\"isOwner\":false,\"roles\":[{\"roleId\":7,\"roleName\":\"Support\"}]}],\"pagination\":{\"total\":\(total),\"page\":\(page),\"pageSize\":1}},\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }
}
