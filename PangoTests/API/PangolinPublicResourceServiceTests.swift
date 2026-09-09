import Foundation
import Testing
@testable import Pango

@Suite("Pangolin public resource service", .serialized)
struct PangolinPublicResourceServiceTests {
    private func makeService() throws -> PangolinPublicResourceService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinPublicResourceService(
            client: PangolinAPIClient(
                configuration: try PangolinAPIConfiguration(baseURLString: "https://api.example.com", apiKey: "synthetic-key"),
                session: URLSession(configuration: configuration)
            ),
            organizationId: "synthetic-org"
        )
    }

    @Test("lists current public resources")
    func listsResources() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/org/synthetic-org/public-resources?pageSize=100&page=1")
            return .init(statusCode: 200, data: Data(#"{"data":{"resources":[{"resourceId":4,"name":"Web","ssl":true,"fullDomain":"web.example.com","sso":false,"http":true,"protocol":"tcp","enabled":true,"wildcard":false,"mode":"http","health":"unknown"}],"pagination":{"total":1,"pageSize":100,"page":1}},"success":true,"error":false,"message":"","status":200}"#.utf8))
        }
        let page = try await makeService().listResources()
        #expect(page.resources.first?.name == "Web")
        #expect(page.pagination.total == 1)
    }

    @Test("lists all public resource pages")
    func listsAllResources() async throws {
        URLProtocolStub.handler = { request in
            let url = try #require(request.url)
            let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let page = try #require(components.queryItems?.first(where: { $0.name == "page" })?.value)

            if page == "1" {
                return .init(
                    statusCode: 200,
                    data: Self.resourcesResponse(names: ["First", "Second"], total: 3, pageSize: 2, page: 1)
                )
            }
            return .init(
                statusCode: 200,
                data: Self.resourcesResponse(names: ["Third"], total: 3, pageSize: 2, page: 2)
            )
        }

        let resources = try await makeService().listAllResources(pageSize: 2)

        #expect(resources.map(\.name) == ["First", "Second", "Third"])
    }

    @Test("creates an HTTP resource using the current mode field")
    func createsHTTPResource() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/org/synthetic-org/public-resource")
            #expect(request.httpMethod == "PUT")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["name"] as? String == "Web")
            #expect(json["mode"] as? String == "http")
            #expect(json["domainId"] as? String == "domain-id")
            #expect(json["subdomain"] as? String == "web")
            return .init(statusCode: 201, data: Self.resourceResponse(name: "Web"))
        }
        let resource = try await makeService().createHTTP(name: "Web", subdomain: "web", domainId: "domain-id")
        #expect(resource.name == "Web")
    }

    @Test("creates a TCP resource with a validated proxy port")
    func createsTCPResource() async throws {
        URLProtocolStub.handler = { request in
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["mode"] as? String == "tcp")
            #expect(json["proxyPort"] as? Int == 2200)
            return .init(statusCode: 201, data: Self.resourceResponse(name: "SSH Port", mode: "tcp", http: false))
        }
        let resource = try await makeService().createRaw(name: "SSH Port", protocol: .tcp, proxyPort: 2200)
        #expect(resource.mode == "tcp")
    }

    @Test("updates only lifecycle fields")
    func updatesResource() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/public-resource/4")
            #expect(request.httpMethod == "POST")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json as? [String: AnyHashable] == ["name": "Renamed", "enabled": false])
            return .init(statusCode: 200, data: Self.resourceResponse(name: "Renamed", enabled: false))
        }
        let resource = try await makeService().update(resourceId: 4, name: "Renamed", enabled: false)
        #expect(!resource.enabled)
    }

    @Test("deletes through the non-legacy public resource route")
    func deletesResource() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/public-resource/4")
            #expect(request.httpMethod == "DELETE")
            return .init(statusCode: 200, data: Data(#"{"data":null,"success":true,"error":false,"message":"","status":200}"#.utf8))
        }
        try await makeService().delete(resourceId: 4)
    }

    private static func resourceResponse(name: String, mode: String = "http", http: Bool = true, enabled: Bool = true) -> Data {
        Data("{\"data\":{\"resourceId\":4,\"name\":\"\(name)\",\"ssl\":false,\"sso\":false,\"http\":\(http),\"protocol\":\"tcp\",\"enabled\":\(enabled),\"wildcard\":false,\"mode\":\"\(mode)\",\"health\":\"unknown\"},\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }

    private static func resourcesResponse(names: [String], total: Int, pageSize: Int, page: Int) -> Data {
        let resources = names.enumerated().map { index, name in
            "{\"resourceId\":\(page * 10 + index),\"name\":\"\(name)\",\"ssl\":false,\"sso\":false,\"http\":true,\"protocol\":\"tcp\",\"enabled\":true,\"wildcard\":false,\"mode\":\"http\",\"health\":\"unknown\"}"
        }.joined(separator: ",")
        return Data("{\"data\":{\"resources\":[\(resources)],\"pagination\":{\"total\":\(total),\"pageSize\":\(pageSize),\"page\":\(page)}},\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
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
