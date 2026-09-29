import Foundation
import Testing
@testable import Pango

@Suite("Pangolin domain service", .serialized)
struct PangolinDomainServiceTests {
    private func makeService() throws -> PangolinDomainService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return PangolinDomainService(
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

    @Test("lists all domain pages using limit and offset")
    func listsAllDomains() async throws {
        URLProtocolStub.handler = { request in
            let url = try #require(request.url)
            let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let offset = try #require(components.queryItems?.first(where: { $0.name == "offset" })?.value)
            #expect(url.path == "/v1/org/synthetic-org/domains")
            #expect(components.queryItems?.first(where: { $0.name == "limit" })?.value == "2")

            if offset == "0" {
                return .init(
                    statusCode: 200,
                    data: Self.domainsResponse(names: ["one.example", "two.example"], total: 3, limit: 2, offset: 0)
                )
            }
            return .init(
                statusCode: 200,
                data: Self.domainsResponse(names: ["three.example"], total: 3, limit: 2, offset: 2)
            )
        }

        let domains = try await makeService().listAllDomains(limit: 2)

        #expect(domains.map(\.baseDomain) == ["one.example", "two.example", "three.example"])
    }

    @Test("loads DNS records from the current endpoint and field names")
    func loadsDNSRecords() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/org/synthetic-org/domain/domain-1/dns-records")
            #expect(request.httpMethod == "GET")
            return .init(
                statusCode: 200,
                data: Data(#"{"data":[{"id":4,"domainId":"domain-1","recordType":"A","baseDomain":"app","value":"203.0.113.8","verified":true}],"success":true,"error":false,"message":"","status":200}"#.utf8)
            )
        }

        let records = try await makeService().listDNSRecords(domainId: "domain-1")

        #expect(records.first?.type == "A")
        #expect(records.first?.name == "app")
        #expect(records.first?.value == "203.0.113.8")
    }

    @Test("returns an empty list when Pangolin has no DNS records")
    func returnsEmptyDNSRecords() async throws {
        URLProtocolStub.handler = { _ in
            .init(
                statusCode: 404,
                data: Data(#"{"data":null,"success":false,"error":true,"message":"No DNS records found for this domain","status":404}"#.utf8)
            )
        }

        let records = try await makeService().listDNSRecords(domainId: "domain-1")

        #expect(records.isEmpty)
    }

    private static func domainsResponse(
        names: [String],
        total: Int,
        limit: Int,
        offset: Int
    ) -> Data {
        let domains = names.enumerated().map { index, name in
            "{\"domainId\":\"domain-\(offset + index)\",\"baseDomain\":\"\(name)\",\"verified\":true,\"type\":\"wildcard\",\"failed\":false,\"tries\":1,\"configManaged\":false,\"certResolver\":null,\"preferWildcardCert\":null,\"errorMessage\":null}"
        }.joined(separator: ",")
        return Data("{\"data\":{\"domains\":[\(domains)],\"pagination\":{\"total\":\(total),\"limit\":\(limit),\"offset\":\(offset)}},\"success\":true,\"error\":false,\"message\":\"\",\"status\":200}".utf8)
    }
}
