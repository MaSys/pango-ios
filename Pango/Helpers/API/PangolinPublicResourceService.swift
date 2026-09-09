import Foundation

struct PublicResourcesPage: Decodable {
    let resources: [Resource]
    let pagination: Pagination
}

enum PublicResourceRawProtocol: String, Encodable {
    case tcp
    case udp
}

struct PangolinPublicResourceService: Sendable {
    private struct HTTPBody: Encodable {
        let name: String
        let subdomain: String
        let domainId: String
        let mode = "http"
    }

    private struct RawBody: Encodable {
        let name: String
        let mode: PublicResourceRawProtocol
        let proxyPort: Int
    }

    private struct UpdateBody: Encodable {
        let name: String?
        let enabled: Bool?
        let ssl: Bool?
    }

    private let client: PangolinAPIClient
    private let organizationId: String

    init(client: PangolinAPIClient, organizationId: String) {
        self.client = client
        self.organizationId = organizationId
    }

    func listResources(page: Int = 1, pageSize: Int = 100) async throws -> PublicResourcesPage {
        let response: PangolinResponse<PublicResourcesPage> = try await client.send(
            .get,
            path: "/org/\(organizationId)/public-resources",
            queryItems: [URLQueryItem(name: "pageSize", value: String(pageSize)), URLQueryItem(name: "page", value: String(page))]
        )
        return try response.requiredData()
    }

    func createHTTP(name: String, subdomain: String, domainId: String) async throws -> Resource {
        let response: PangolinResponse<Resource> = try await client.send(
            .put,
            path: "/org/\(organizationId)/public-resource",
            body: HTTPBody(name: name, subdomain: subdomain, domainId: domainId)
        )
        return try response.requiredData()
    }

    func createRaw(name: String, protocol rawProtocol: PublicResourceRawProtocol, proxyPort: Int) async throws -> Resource {
        guard (1...65_535).contains(proxyPort) else {
            throw PangolinAPIError.serverRejected(status: 400, message: "INVALID_PORT")
        }
        let response: PangolinResponse<Resource> = try await client.send(
            .put,
            path: "/org/\(organizationId)/public-resource",
            body: RawBody(name: name, mode: rawProtocol, proxyPort: proxyPort)
        )
        return try response.requiredData()
    }

    func update(resourceId: Int, name: String? = nil, enabled: Bool? = nil, ssl: Bool? = nil) async throws -> Resource {
        let response: PangolinResponse<Resource> = try await client.send(
            .post,
            path: "/public-resource/\(resourceId)",
            body: UpdateBody(name: name, enabled: enabled, ssl: ssl)
        )
        return try response.requiredData()
    }

    func delete(resourceId: Int) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(.delete, path: "/public-resource/\(resourceId)")
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }
}

private extension PangolinResponse {
    func requiredData() throws -> Value {
        guard success, !error else {
            throw PangolinAPIError.serverRejected(status: status, message: message)
        }
        guard let data else { throw PangolinAPIError.decoding }
        return data
    }
}
