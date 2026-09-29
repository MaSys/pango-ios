import Foundation

struct PangolinClientSite: Decodable {
    let siteId: Int
    let siteName: String?
}

struct PangolinClient: Decodable {
    let clientId: Int
    let name: String?
    let niceId: String?
    let type: String?
    let online: Bool?
    let subnet: String?
    let userEmail: String?
    let approvalState: String?
    let blocked: Bool?
    let archived: Bool?
    let sites: [PangolinClientSite]?

    var statusKey: String {
        if archived == true { return "ARCHIVED" }
        if blocked == true { return "BLOCKED" }
        switch approvalState {
        case "pending": return "PENDING"
        case "denied": return "DENIED"
        default: return "ACTIVE"
        }
    }
}

struct PangolinClientsPage: Decodable {
    let clients: [PangolinClient]
    let pagination: Pagination
}

struct PangolinUserDevicesPage: Decodable {
    let devices: [PangolinClient]
    let pagination: Pagination
}

struct PangolinClientService: Sendable {
    private let client: PangolinAPIClient
    private let organizationId: String

    init(client: PangolinAPIClient, organizationId: String) {
        self.client = client
        self.organizationId = organizationId
    }

    func listAllMachines(pageSize: Int = 100) async throws -> [PangolinClient] {
        try await listAll(pageSize: pageSize, path: "/org/\(organizationId)/clients",
                          status: "active,blocked,archived") { (page: PangolinClientsPage) in
            (page.clients, page.pagination)
        }
    }

    func listAllUserDevices(pageSize: Int = 100) async throws -> [PangolinClient] {
        try await listAll(pageSize: pageSize, path: "/org/\(organizationId)/user-devices",
                          status: "active,pending,denied,blocked,archived") { (page: PangolinUserDevicesPage) in
            (page.devices, page.pagination)
        }
    }

    private func listAll<Page: Decodable>(
        pageSize: Int,
        path: String,
        status: String,
        extract: (Page) -> ([PangolinClient], Pagination)
    ) async throws -> [PangolinClient] {
        var clients: [PangolinClient] = []
        var requestedPage = 1
        while true {
            let response: PangolinResponse<Page> = try await client.send(
                .get, path: path,
                queryItems: [
                    URLQueryItem(name: "pageSize", value: String(pageSize)),
                    URLQueryItem(name: "page", value: String(requestedPage)),
                    URLQueryItem(name: "status", value: status)
                ]
            )
            guard response.success, !response.error else {
                throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
            }
            guard let data = response.data else { throw PangolinAPIError.decoding }
            let (items, pagination) = extract(data)
            clients.append(contentsOf: items)
            guard pagination.pageSize > 0,
                  ResourcePagination.hasNextPage(total: pagination.total, page: pagination.page, pageSize: pagination.pageSize) else {
                return clients
            }
            let nextPage = pagination.page + 1
            guard nextPage > requestedPage else { throw PangolinAPIError.decoding }
            requestedPage = nextPage
        }
    }
}
