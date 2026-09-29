import Foundation
import Testing
@testable import Pango

@Suite("Pangolin clients", .serialized)
struct PangolinClientServiceTests {
    private func service() throws -> PangolinClientService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinClientService(client: PangolinAPIClient(
            configuration: try PangolinAPIConfiguration(baseURLString: "https://api.example.com", apiKey: "synthetic-key"),
            session: URLSession(configuration: configuration)
        ), organizationId: "org-1")
    }

    @Test func listsAllMachineClientPages() async throws {
        URLProtocolStub.handler = { request in
            let url = try #require(request.url)
            #expect(url.path == "/v1/org/org-1/clients")
            let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
            #expect(query.first { $0.name == "pageSize" }?.value == "1")
            #expect(query.first { $0.name == "status" }?.value == "active,blocked,archived")
            let page = try #require(query.first { $0.name == "page" }?.value)
            return .init(statusCode: 200, data: Self.response("clients", id: page, page: page))
        }
        let clients = try await service().listAllMachines(pageSize: 1)
        #expect(clients.map(\.clientId) == [1, 2])
        #expect(clients.first?.sites?.first?.siteName == "Home")
        #expect(clients.first?.statusKey == "ACTIVE")
    }

    @Test func listsAllUserDevicePages() async throws {
        URLProtocolStub.handler = { request in
            let url = try #require(request.url)
            #expect(url.path == "/v1/org/org-1/user-devices")
            let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
            #expect(query.first { $0.name == "status" }?.value == "active,pending,denied,blocked,archived")
            let page = try #require(query.first { $0.name == "page" }?.value)
            return .init(statusCode: 200, data: Self.response("devices", id: page, page: page, userEmail: "user@example.com"))
        }
        let devices = try await service().listAllUserDevices(pageSize: 1)
        #expect(devices.map(\.clientId) == [1, 2])
        #expect(devices.first?.userEmail == "user@example.com")
    }

    @Test func rejectsRepeatedPagination() async throws {
        URLProtocolStub.handler = { _ in
            .init(statusCode: 200, data: Self.response("clients", id: "1", page: "1", total: 3))
        }
        await #expect(throws: PangolinAPIError.decoding) {
            try await service().listAllMachines(pageSize: 1)
        }
    }

    @Test func preservesPermissionError() async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 403, data: Data()) }
        await #expect(throws: PangolinAPIError.forbidden) {
            try await service().listAllUserDevices()
        }
    }

    @Test func getsClientDetailFromDedicatedEndpoint() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.httpMethod == "GET")
            #expect(request.url?.path == "/v1/client/7")
            let data = Data(#"{"data":{"clientId":7,"name":"Work Laptop","niceId":"work-laptop","type":"olm","online":true,"subnet":"10.0.0.2/32","userEmail":"user@example.com","approvalState":"approved","blocked":false,"archived":false,"fingerprint":{"platform":"macos","osVersion":"15.5","deviceModel":"MacBook Pro"}},"success":true,"error":false,"message":"","status":200}"#.utf8)
            return .init(statusCode: 200, data: data)
        }
        let detail = try await service().getClient(clientId: 7)
        #expect(detail.clientId == 7)
        #expect(detail.fingerprint?.platform == "macos")
        #expect(detail.fingerprint?.osVersion == "15.5")
    }

    @Test func preservesDetailPermissionError() async throws {
        URLProtocolStub.handler = { _ in .init(statusCode: 403, data: Data()) }
        await #expect(throws: PangolinAPIError.forbidden) {
            try await service().getClient(clientId: 7)
        }
    }

    private static func response(_ key: String, id: String, page: String, total: Int = 2, userEmail: String? = nil) -> Data {
        let email = userEmail.map { "\"\($0)\"" } ?? "null"
        let sites = key == "clients" ? #""sites":[{"siteId":3,"siteName":"Home","siteNiceId":null}],"# : ""
        return Data("{\"data\":{\"\(key)\":[{\"clientId\":\(id),\"name\":\"Client \(id)\",\"type\":\"olm\",\"online\":true,\"blocked\":false,\"archived\":false,\"userEmail\":\(email),\(sites)\"approvalState\":\"approved\"}],\"pagination\":{\"total\":\(total),\"page\":\(page),\"pageSize\":1}},\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }
}
