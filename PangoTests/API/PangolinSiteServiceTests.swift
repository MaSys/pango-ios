import Foundation
import Testing
@testable import Pango

@Suite("Pangolin site service", .serialized)
struct PangolinSiteServiceTests {
    private func makeService() throws -> PangolinSiteService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let client = PangolinAPIClient(
            configuration: try PangolinAPIConfiguration(
                baseURLString: "https://api.example.com",
                apiKey: "synthetic-key"
            ),
            session: URLSession(configuration: configuration)
        )
        return PangolinSiteService(client: client, organizationId: "synthetic-org")
    }

    @Test("lists sites using the current paginated response")
    func listsSites() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/org/synthetic-org/sites?pageSize=100&page=1")
            return .init(
                statusCode: 200,
                data: Data(#"{"data":{"sites":[{"siteId":7,"niceId":"lab","name":"Lab","pubKey":null,"subnet":null,"megabytesIn":12.5,"megabytesOut":3.25,"orgName":"Synthetic","type":"newt","online":false,"address":"100.89.0.2/24","newtVersion":"1.5.0","exitNodeId":2,"exitNodeName":"Region","exitNodeEndpoint":"example.com","remoteExitNodeId":null,"resourceCount":4,"status":"approved","newtUpdateAvailable":false,"labels":[]}],"pagination":{"total":1,"pageSize":100,"page":1}},"success":true,"error":false,"message":"Sites retrieved successfully","status":200}"#.utf8)
            )
        }

        let page = try await makeService().listSites()

        #expect(page.sites == [Site(siteId: 7, niceId: "lab", name: "Lab", pubKey: nil, subnet: nil, megabytesIn: 12.5, megabytesOut: 3.25, orgName: "Synthetic", type: "newt", online: false, address: "100.89.0.2/24", newtVersion: "1.5.0", newtUpdateAvailable: false, uptimePercent: nil, pending: nil, exitNodeId: 2, exitNodeName: "Region", exitNodeEndpoint: "example.com", remoteExitNodeId: nil, resourceCount: 4, status: "approved", newtId: nil, secret: nil)])
        #expect(page.pagination.total == 1)
    }

    @Test("creates a Newt site and returns its one-time credentials")
    func createsNewtSite() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/org/synthetic-org/site")
            #expect(request.httpMethod == "PUT")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json["name"] as? String == "New Lab")
            #expect(json["type"] as? String == "newt")
            #expect(json.count == 2)
            return .init(
                statusCode: 201,
                data: Data(#"{"data":{"siteId":8,"niceId":"new-lab","name":"New Lab","orgId":"synthetic-org","type":"newt","status":"approved","newtId":"newt-id","secret":"one-time-secret"},"success":true,"error":false,"message":"Site created successfully","status":201}"#.utf8)
            )
        }

        let created = try await makeService().createNewtSite(name: "New Lab")

        #expect(created.site.name == "New Lab")
        #expect(created.credentials == SiteCredentials(id: "newt-id", secret: "one-time-secret"))
    }

    @Test("gets complete site details by numeric identifier")
    func getsSiteDetails() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/site/7")
            #expect(request.httpMethod == "GET")
            return .init(
                statusCode: 200,
                data: Data(#"{"data":{"siteId":7,"niceId":"lab","name":"Lab","orgId":"synthetic-org","type":"newt","status":"approved","online":true,"newtId":"newt-id","newtVersion":"1.5.0","countryCode":"US"},"success":true,"error":false,"message":"Site retrieved successfully","status":200}"#.utf8)
            )
        }

        let site = try await makeService().getSite(siteId: 7)

        #expect(site.siteId == 7)
        #expect(site.newtId == "newt-id")
    }

    @Test("renames a site without changing unrelated settings")
    func renamesSite() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/v1/site/8")
            #expect(request.httpMethod == "POST")
            let body = try #require(request.bodyData)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            #expect(json as? [String: String] == ["name": "Renamed Lab"])
            return .init(
                statusCode: 200,
                data: Data(#"{"data":{"siteId":8,"niceId":"new-lab","name":"Renamed Lab","orgId":"synthetic-org","type":"newt","status":"approved"},"success":true,"error":false,"message":"Site updated successfully","status":200}"#.utf8)
            )
        }

        let site = try await makeService().renameSite(siteId: 8, name: "Renamed Lab")

        #expect(site.name == "Renamed Lab")
    }

    @Test("deletes a site without deleting associated resources")
    func deletesSiteSafely() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString == "https://api.example.com/v1/site/8?deleteResources=false")
            #expect(request.httpMethod == "DELETE")
            return .init(
                statusCode: 200,
                data: Data(#"{"data":null,"success":true,"error":false,"message":"Site deleted successfully","status":200}"#.utf8)
            )
        }

        try await makeService().deleteSite(siteId: 8)
    }
}

private extension URLRequest {
    var bodyData: Data? {
        if let httpBody {
            return httpBody
        }
        guard let httpBodyStream else {
            return nil
        }
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
