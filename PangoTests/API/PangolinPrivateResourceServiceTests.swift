import Foundation
import Testing
@testable import Pango

@Suite("Pangolin private resource service", .serialized)
struct PangolinPrivateResourceServiceTests {
    private func makeService() throws -> PangolinPrivateResourceService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinPrivateResourceService(
            client: PangolinAPIClient(
                configuration: try PangolinAPIConfiguration(
                    baseURLString: "https://api.example.com",
                    apiKey: "synthetic-key"
                ),
                session: URLSession(configuration: configuration)
            ),
            organizationId: "synthetic-org"
        )
    }

    @Test("lists all private resource pages")
    func listsAllResources() async throws {
        URLProtocolStub.handler = { request in
            let url = try #require(request.url)
            let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let page = try #require(components.queryItems?.first(where: { $0.name == "page" })?.value)
            #expect(url.path == "/v1/org/synthetic-org/private-resources")

            if page == "1" {
                return .init(statusCode: 200, data: Self.listResponse(names: ["First", "Second"], total: 3, pageSize: 2, page: 1))
            }
            return .init(statusCode: 200, data: Self.listResponse(names: ["Third"], total: 3, pageSize: 2, page: 2))
        }

        let resources = try await makeService().listAllResources(pageSize: 2)

        #expect(resources.map(\.name) == ["First", "Second", "Third"])
    }

    @Test("creates through the current route with explicit empty access assignments")
    func createsResource() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/org/synthetic-org/private-resource")
            #expect(request.httpMethod == "PUT")
            let json = try Self.jsonBody(request)
            #expect(json["name"] as? String == "Database")
            #expect(json["siteIds"] as? [Int] == [7])
            #expect(json["mode"] as? String == "host")
            #expect(json["userIds"] as? [String] == [])
            #expect(json["roleIds"] as? [Int] == [])
            #expect(json["clientIds"] as? [Int] == [])
            return .init(statusCode: 201, data: Self.mutationResponse(name: "Database"))
        }

        try await makeService().create(configuration: Self.configuration(name: "Database"))
    }

    @Test("updates without changing access assignments")
    func updatesWithoutAccessAssignments() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/private-resource/9")
            #expect(request.httpMethod == "POST")
            let json = try Self.jsonBody(request)
            #expect(json["name"] as? String == "Renamed Database")
            #expect(json["siteIds"] as? [Int] == [7])
            #expect(!json.keys.contains("userIds"))
            #expect(!json.keys.contains("roleIds"))
            #expect(!json.keys.contains("clientIds"))
            return .init(statusCode: 200, data: Self.mutationResponse(name: "Renamed Database"))
        }

        try await makeService().update(
            resourceId: 9,
            configuration: Self.configuration(name: "Renamed Database")
        )
    }

    @Test("deletes through the current private resource route")
    func deletesResource() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/private-resource/9")
            #expect(request.httpMethod == "DELETE")
            return .init(
                statusCode: 200,
                data: Data(#"{"data":null,"success":true,"error":false,"message":"","status":200}"#.utf8)
            )
        }

        try await makeService().delete(resourceId: 9)
    }

    private static func configuration(name: String) -> PrivateResourceConfiguration {
        PrivateResourceConfiguration(
            name: name,
            siteIds: [7],
            mode: "host",
            ssl: false,
            scheme: nil,
            destinationPort: nil,
            destination: "10.0.0.8",
            alias: "database.internal",
            tcpPortRangeString: "5432",
            udpPortRangeString: "*",
            disableIcmp: false,
            domainId: nil,
            subdomain: nil
        )
    }

    private static func jsonBody(_ request: URLRequest) throws -> [String: Any] {
        let body = try #require(request.bodyData)
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    private static func mutationResponse(name: String) -> Data {
        Data("{\"data\":{\"siteResourceId\":9,\"orgId\":\"synthetic-org\",\"name\":\"\(name)\"},\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }

    private static func listResponse(names: [String], total: Int, pageSize: Int, page: Int) -> Data {
        let resources = names.enumerated().map { index, name in
            resourceJSON(name: name, id: page * 10 + index)
        }.joined(separator: ",")
        return Data("{\"data\":{\"siteResources\":[\(resources)],\"pagination\":{\"total\":\(total),\"pageSize\":\(pageSize),\"page\":\(page)}},\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }

    private static func resourceJSON(name: String, id: Int) -> String {
        "{\"siteResourceId\":\(id),\"orgId\":\"synthetic-org\",\"niceId\":\"resource-\(id)\",\"name\":\"\(name)\",\"mode\":\"host\",\"ssl\":false,\"scheme\":null,\"proxyPort\":null,\"destinationPort\":null,\"destination\":\"10.0.0.8\",\"enabled\":true,\"alias\":\"database.internal\",\"aliasAddress\":\"100.64.0.8\",\"tcpPortRangeString\":\"5432\",\"udpPortRangeString\":\"*\",\"disableIcmp\":false,\"authDaemonMode\":\"site\",\"authDaemonPort\":22,\"subdomain\":null,\"domainId\":null,\"fullDomain\":null,\"networkId\":4,\"defaultNetworkId\":null,\"siteNames\":[\"Lab\"],\"siteNiceIds\":[\"lab\"],\"siteIds\":[7],\"siteAddresses\":[\"100.64.0.2\"],\"siteOnlines\":[true]}"
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
