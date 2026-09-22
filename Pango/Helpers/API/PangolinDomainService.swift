import Foundation

struct DomainPagination: Decodable, Equatable {
    let total: Int
    let limit: Int
    let offset: Int
}

struct DomainsPage: Decodable {
    let domains: [Domain]
    let pagination: DomainPagination
}

struct PangolinDomainService: Sendable {
    private let client: PangolinAPIClient
    private let organizationId: String

    init(client: PangolinAPIClient, organizationId: String) {
        self.client = client
        self.organizationId = organizationId
    }

    func listDomains(limit: Int = 1_000, offset: Int = 0) async throws -> DomainsPage {
        let response: PangolinResponse<DomainsPage> = try await client.send(
            .get,
            path: "/org/\(organizationId)/domains",
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset))
            ]
        )
        return try response.requireDomainData()
    }

    func listAllDomains(limit: Int = 1_000) async throws -> [Domain] {
        var domains: [Domain] = []
        var requestedOffset = 0

        while true {
            let result = try await listDomains(limit: limit, offset: requestedOffset)
            domains.append(contentsOf: result.domains)

            guard result.pagination.limit > 0,
                  result.pagination.offset + result.pagination.limit < result.pagination.total else {
                return domains
            }

            let nextOffset = result.pagination.offset + result.pagination.limit
            guard nextOffset > requestedOffset else { throw PangolinAPIError.decoding }
            requestedOffset = nextOffset
        }
    }

    func listDNSRecords(domainId: String) async throws -> [DnsRecord] {
        do {
            let response: PangolinResponse<[DnsRecord]> = try await client.send(
                .get,
                path: "/org/\(organizationId)/domain/\(domainId)/dns-records"
            )
            return try response.requireDomainData()
        } catch PangolinAPIError.unsupported {
            return []
        }
    }
}

private extension PangolinResponse {
    func requireDomainData() throws -> Value {
        guard success, !error else {
            throw PangolinAPIError.serverRejected(status: status, message: message)
        }
        guard let data else { throw PangolinAPIError.decoding }
        return data
    }
}
