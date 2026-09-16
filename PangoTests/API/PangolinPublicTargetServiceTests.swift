import Foundation
import Testing
@testable import Pango

@Suite("Pangolin public target service", .serialized)
struct PangolinPublicTargetServiceTests {
    private func makeService() throws -> PangolinPublicTargetService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinPublicTargetService(
            client: PangolinAPIClient(
                configuration: try PangolinAPIConfiguration(
                    baseURLString: "https://api.example.com",
                    apiKey: "synthetic-key"
                ),
                session: URLSession(configuration: configuration)
            )
        )
    }

    @Test("lists every target page using the current public resource route")
    func listsAllTargets() async throws {
        URLProtocolStub.handler = { request in
            let url = try #require(request.url)
            let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
            #expect(components.path == "/v1/public-resource/4/targets")
            let offset = try #require(components.queryItems?.first(where: { $0.name == "offset" })?.value)
            #expect(components.queryItems?.first(where: { $0.name == "limit" })?.value == "2")

            if offset == "0" {
                return .init(statusCode: 200, data: Self.targetsResponse(
                    targets: [Self.targetJSON(id: 1, ip: "10.0.0.1"), Self.targetJSON(id: 2, ip: "10.0.0.2")],
                    total: 3,
                    limit: 2,
                    offset: 0
                ))
            }
            #expect(offset == "2")
            return .init(statusCode: 200, data: Self.targetsResponse(
                targets: [Self.targetJSON(id: 3, ip: "10.0.0.3")],
                total: 3,
                limit: 2,
                offset: 2
            ))
        }

        let targets = try await makeService().listAllTargets(resourceId: 4, limit: 2)

        #expect(targets.map(\.targetId) == [1, 2, 3])
        #expect(targets.first?.healthCheck == true)
        #expect(targets.first?.healthStatus == "healthy")
        #expect(targets.first?.healthCheckHostname == "health.internal")
        #expect(targets.first?.path == "/api")
        #expect(targets.first?.pathMatchType == "prefix")
        #expect(targets.first?.pathRewriting == "/v2")
        #expect(targets.first?.rewritePathType == "prefix")
    }

    @Test("lists targets from a legacy response without pagination")
    func listsLegacyTargets() async throws {
        URLProtocolStub.handler = { _ in
            .init(
                statusCode: 200,
                data: Data("{\"data\":{\"targets\":[\(Self.targetJSON(id: 1, ip: "10.0.0.1"))]},\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
            )
        }

        let targets = try await makeService().listAllTargets(resourceId: 4)

        #expect(targets.map(\.targetId) == [1])
    }

    @Test("creates an HTTP target with routing and health settings")
    func createsHTTPTarget() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/public-resource/4/target")
            #expect(request.httpMethod == "PUT")
            let body = try #require(request.targetBodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["siteId"] as? Int == 7)
            #expect(json["ip"] as? String == "app.internal")
            #expect(json["port"] as? Int == 8443)
            #expect(json["method"] as? String == "https")
            #expect(json["enabled"] as? Bool == true)
            #expect(json["hcEnabled"] as? Bool == true)
            #expect(json["hcHostname"] as? String == "app.internal")
            #expect(json["hcPort"] as? Int == 8443)
            #expect(json["hcScheme"] as? String == "https")
            #expect(json["hcMode"] as? String == "http")
            #expect(json["hcPath"] as? String == "/")
            #expect(json["hcMethod"] as? String == "GET")
            #expect(json["path"] as? String == "/api")
            #expect(json["pathMatchType"] as? String == "prefix")
            #expect(json["rewritePath"] as? String == "/v2")
            #expect(json["rewritePathType"] as? String == "prefix")
            return .init(statusCode: 201, data: Self.targetResponse(id: 8, ip: "app.internal"))
        }

        let target = try await makeService().createTarget(
            resourceId: 4,
            configuration: PublicTargetConfiguration(
                siteId: 7,
                ip: "app.internal",
                port: 8443,
                method: .https,
                enabled: true,
                healthCheck: true,
                path: "/api",
                pathMatchType: .prefix,
                rewritePath: "/v2",
                rewritePathType: .prefix
            )
        )

        #expect(target.targetId == 8)
    }

    @Test("enabling a health check supplies the complete probe configuration")
    func enablesHealthCheck() async throws {
        URLProtocolStub.handler = { request in
            let body = try #require(request.targetBodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["hcEnabled"] as? Bool == true)
            #expect(json["hcHostname"] as? String == "192.168.68.244")
            #expect(json["hcPort"] as? Int == 5232)
            #expect(json["hcScheme"] as? String == "http")
            #expect(json["hcMode"] as? String == "http")
            #expect(json["hcPath"] as? String == "/")
            #expect(json["hcMethod"] as? String == "GET")
            #expect(json["hcInterval"] as? Int == 30)
            #expect(json["hcUnhealthyInterval"] as? Int == 30)
            #expect(json["hcTimeout"] as? Int == 5)
            #expect(json["hcFollowRedirects"] as? Bool == true)
            #expect(json["hcHealthyThreshold"] as? Int == 1)
            #expect(json["hcUnhealthyThreshold"] as? Int == 1)
            #expect(json["hcStatus"] == nil || json["hcStatus"] is NSNull)
            return .init(statusCode: 200, data: Self.targetResponse(id: 8, ip: "192.168.68.244"))
        }

        _ = try await makeService().updateTarget(
            targetId: 8,
            configuration: PublicTargetConfiguration(
                siteId: 1, ip: "192.168.68.244", port: 5232, method: .http,
                enabled: true, healthCheck: true, path: nil, pathMatchType: nil,
                rewritePath: nil, rewritePathType: nil
            )
        )
    }

    @Test("omits HTTP-only fields when creating a raw target")
    func createsRawTarget() async throws {
        URLProtocolStub.handler = { request in
            let body = try #require(request.targetBodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["method"] == nil)
            #expect(json["path"] == nil)
            #expect(json["pathMatchType"] == nil)
            #expect(json["rewritePath"] == nil)
            #expect(json["rewritePathType"] == nil)
            return .init(statusCode: 201, data: Self.targetResponse(id: 9, ip: "10.0.0.9"))
        }

        _ = try await makeService().createTarget(
            resourceId: 5,
            configuration: PublicTargetConfiguration(
                siteId: 7,
                ip: "10.0.0.9",
                port: 9000,
                method: nil,
                enabled: true,
                healthCheck: false,
                path: nil,
                pathMatchType: nil,
                rewritePath: nil,
                rewritePathType: nil
            )
        )
    }

    @Test("preserves custom health settings when enabling or disabling a target", arguments: [true, false], [true, false])
    func preservesHealthSettings(enabled: Bool, storedHeaders: Bool) async throws {
        let healthJSON = Data(#"""
        {"hcHostname":"probe.internal","hcPort":9443,"hcMode":"http",
         "hcScheme":"https","hcPath":"/ready","hcMethod":"HEAD",
         "hcInterval":60,"hcUnhealthyInterval":10,"hcTimeout":8,
         "hcHeaders":[{"name":"Host","value":"app.internal"}],
         "hcFollowRedirects":false,"hcStatus":204,"hcTlsServerName":"tls.internal",
         "hcHealthyThreshold":3,"hcUnhealthyThreshold":2}
        """#.utf8)
        let expected = try #require(JSONSerialization.jsonObject(with: healthJSON) as? [String: Any])
        var responseJSON = try #require(JSONSerialization.jsonObject(
            with: Data(Self.targetJSON(id: 8, ip: "app.internal").utf8)
        ) as? [String: Any])
        responseJSON.merge(expected) { _, new in new }
        if storedHeaders {
            responseJSON["hcHeaders"] = #"[{"name":"Host","value":"app.internal"}]"#
        }
        let target = try JSONDecoder().decode(Target.self, from: JSONSerialization.data(withJSONObject: responseJSON))
        URLProtocolStub.handler = { request in
            let body = try #require(request.targetBodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["hcEnabled"] as? Bool == enabled)
            let actual = json.filter { $0.key.hasPrefix("hc") && $0.key != "hcEnabled" }
            #expect(NSDictionary(dictionary: actual).isEqual(to: expected))
            return .init(statusCode: 200, data: Self.targetResponse(id: 8, ip: "app.internal"))
        }

        _ = try await makeService().updateTarget(
            targetId: target.targetId,
            configuration: PublicTargetConfiguration(
                siteId: 7, ip: "app.internal", port: 8443, method: .https,
                enabled: true, healthCheck: enabled, path: nil, pathMatchType: nil,
                rewritePath: nil, rewritePathType: nil,
                healthCheckConfiguration: target.healthCheckConfiguration
            )
        )
    }

    @Test("raw targets use TCP health checks")
    func enablesTCPHealthCheck() async throws {
        URLProtocolStub.handler = { request in
            let body = try #require(request.targetBodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["hcMode"] as? String == "tcp")
            #expect(json["hcPort"] as? Int == 5432)
            #expect(json["hcInterval"] as? Int == 30)
            return .init(statusCode: 200, data: Self.targetResponse(id: 8, ip: "db.internal"))
        }

        _ = try await makeService().updateTarget(
            targetId: 8,
            configuration: PublicTargetConfiguration(
                siteId: 7, ip: "db.internal", port: 5432, method: nil,
                enabled: true, healthCheck: true, path: nil, pathMatchType: nil,
                rewritePath: nil, rewritePathType: nil
            )
        )
    }

    @Test("updates a target through its current route")
    func updatesTarget() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/target/8")
            #expect(request.httpMethod == "POST")
            let body = try #require(request.targetBodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["siteId"] as? Int == 7)
            #expect(json["enabled"] as? Bool == false)
            #expect(json["hcEnabled"] as? Bool == false)
            #expect(json["hcHostname"] as? String == "health.internal")
            return .init(statusCode: 200, data: Self.targetResponse(id: 8, ip: "app.internal"))
        }

        let target = try await makeService().updateTarget(
            targetId: 8,
            configuration: PublicTargetConfiguration(
                siteId: 7,
                ip: "app.internal",
                port: 8443,
                method: .https,
                enabled: false,
                healthCheck: false,
                path: nil,
                pathMatchType: nil,
                rewritePath: nil,
                rewritePathType: nil,
                healthCheckHostname: "health.internal"
            )
        )

        #expect(target.targetId == 8)
    }

    @Test("deletes a target through its current route")
    func deletesTarget() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/target/8")
            #expect(request.httpMethod == "DELETE")
            return .init(
                statusCode: 200,
                data: Data(#"{"data":null,"success":true,"error":false,"message":"","status":200}"#.utf8)
            )
        }

        try await makeService().deleteTarget(targetId: 8)
    }

    private static func targetsResponse(targets: [String], total: Int, limit: Int, offset: Int) -> Data {
        Data("{\"data\":{\"targets\":[\(targets.joined(separator: ","))],\"pagination\":{\"total\":\(total),\"limit\":\(limit),\"offset\":\(offset)}},\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }

    private static func targetJSON(id: Int, ip: String, includeSiteType: Bool = true) -> String {
        let siteType = includeSiteType ? "\"siteType\":\"newt\"," : ""
        return "{\"targetId\":\(id),\"method\":\"https\",\"ip\":\"\(ip)\",\"port\":443,\"enabled\":true,\(siteType)\"siteId\":7,\"hcEnabled\":true,\"hcHealth\":\"healthy\",\"hcHostname\":\"health.internal\",\"path\":\"/api\",\"pathMatchType\":\"prefix\",\"rewritePath\":\"/v2\",\"rewritePathType\":\"prefix\"}"
    }

    private static func targetResponse(id: Int, ip: String) -> Data {
        Data("{\"data\":\(targetJSON(id: id, ip: ip, includeSiteType: false)),\"success\":true,\"error\":false,\"message\":\"\",\"status\":201}".utf8)
    }
}

private extension URLRequest {
    var targetBodyData: Data? {
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
