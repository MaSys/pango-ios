import Foundation

struct PrivateResourcesPage: Decodable {
    let siteResources: [PrivateResource]
    let pagination: Pagination
}

struct PrivateResourceConfiguration: Sendable {
    let name: String
    let siteIds: [Int]
    let mode: String
    let ssl: Bool
    let scheme: String?
    let destinationPort: Int?
    let destination: String
    let alias: String?
    let tcpPortRangeString: String?
    let udpPortRangeString: String?
    let disableIcmp: Bool?
    let domainId: String?
    let subdomain: String?
}

struct PangolinPrivateResourceService: Sendable {
    private struct CreateBody: Encodable {
        let name: String
        let siteIds: [Int]
        let mode: String
        let ssl: Bool
        let scheme: String?
        let destinationPort: Int?
        let destination: String
        let alias: String?
        let userIds: [String] = []
        let roleIds: [Int] = []
        let clientIds: [Int] = []
        let tcpPortRangeString: String?
        let udpPortRangeString: String?
        let disableIcmp: Bool?
        let domainId: String?
        let subdomain: String?

        init(configuration: PrivateResourceConfiguration) {
            name = configuration.name
            siteIds = configuration.siteIds
            mode = configuration.mode
            ssl = configuration.ssl
            scheme = configuration.scheme
            destinationPort = configuration.destinationPort
            destination = configuration.destination
            alias = configuration.alias
            tcpPortRangeString = configuration.tcpPortRangeString
            udpPortRangeString = configuration.udpPortRangeString
            disableIcmp = configuration.disableIcmp
            domainId = configuration.domainId
            subdomain = configuration.subdomain
        }
    }

    private struct UpdateBody: Encodable {
        let name: String
        let siteIds: [Int]
        let mode: String
        let ssl: Bool
        let scheme: String?
        let destinationPort: Int?
        let destination: String
        let alias: String?
        let tcpPortRangeString: String?
        let udpPortRangeString: String?
        let disableIcmp: Bool?
        let domainId: String?
        let subdomain: String?

        init(configuration: PrivateResourceConfiguration) {
            name = configuration.name
            siteIds = configuration.siteIds
            mode = configuration.mode
            ssl = configuration.ssl
            scheme = configuration.scheme
            destinationPort = configuration.destinationPort
            destination = configuration.destination
            alias = configuration.alias
            tcpPortRangeString = configuration.tcpPortRangeString
            udpPortRangeString = configuration.udpPortRangeString
            disableIcmp = configuration.disableIcmp
            domainId = configuration.domainId
            subdomain = configuration.subdomain
        }
    }

    private let client: PangolinAPIClient
    private let organizationId: String

    init(client: PangolinAPIClient, organizationId: String) {
        self.client = client
        self.organizationId = organizationId
    }

    func listResources(page: Int = 1, pageSize: Int = 100) async throws -> PrivateResourcesPage {
        let response: PangolinResponse<PrivateResourcesPage> = try await client.send(
            .get,
            path: "/org/\(organizationId)/private-resources",
            queryItems: [
                URLQueryItem(name: "pageSize", value: String(pageSize)),
                URLQueryItem(name: "page", value: String(page))
            ]
        )
        return try response.requirePrivateResourceData()
    }

    func listAllResources(pageSize: Int = ResourcePagination.pageSize) async throws -> [PrivateResource] {
        var resources: [PrivateResource] = []
        var requestedPage = 1

        while true {
            let result = try await listResources(page: requestedPage, pageSize: pageSize)
            resources.append(contentsOf: result.siteResources)

            guard result.pagination.pageSize > 0,
                  ResourcePagination.hasNextPage(
                    total: result.pagination.total,
                    page: result.pagination.page,
                    pageSize: result.pagination.pageSize
                  ) else {
                return resources
            }

            let nextPage = result.pagination.page + 1
            guard nextPage > requestedPage else { throw PangolinAPIError.decoding }
            requestedPage = nextPage
        }
    }

    func create(configuration: PrivateResourceConfiguration) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .put,
            path: "/org/\(organizationId)/private-resource",
            body: CreateBody(configuration: configuration)
        )
        try response.requirePrivateResourceSuccess()
    }

    func update(resourceId: Int, configuration: PrivateResourceConfiguration) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .post,
            path: "/private-resource/\(resourceId)",
            body: UpdateBody(configuration: configuration)
        )
        try response.requirePrivateResourceSuccess()
    }

    func delete(resourceId: Int) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .delete,
            path: "/private-resource/\(resourceId)"
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }
}

private extension PangolinResponse {
    func requirePrivateResourceData() throws -> Value {
        guard success, !error else {
            throw PangolinAPIError.serverRejected(status: status, message: message)
        }
        guard let data else { throw PangolinAPIError.decoding }
        return data
    }

    func requirePrivateResourceSuccess() throws {
        guard success, !error else {
            throw PangolinAPIError.serverRejected(status: status, message: message)
        }
    }
}
