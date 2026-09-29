import Foundation

struct RolesPage: Decodable {
    let roles: [Role]
    let pagination: Pagination
}

struct PangolinRoleService: Sendable {
    private struct CreateBody: Encodable {
        let name: String
        let description: String
    }

    private struct DeleteBody: Encodable {
        let roleId: Int
    }

    private let client: PangolinAPIClient
    private let organizationId: String

    init(client: PangolinAPIClient, organizationId: String) {
        self.client = client
        self.organizationId = organizationId
    }

    func listAllRoles(pageSize: Int = 1_000) async throws -> [Role] {
        var roles: [Role] = []
        var requestedPage = 1
        while true {
            let response: PangolinResponse<RolesPage> = try await client.send(
                .get, path: "/org/\(organizationId)/roles",
                queryItems: [
                    URLQueryItem(name: "pageSize", value: String(pageSize)),
                    URLQueryItem(name: "page", value: String(requestedPage))
                ]
            )
            let result = try response.requireRoleData()
            roles.append(contentsOf: result.roles)
            guard result.pagination.pageSize > 0,
                  ResourcePagination.hasNextPage(total: result.pagination.total,
                    page: result.pagination.page, pageSize: result.pagination.pageSize) else {
                return roles
            }
            let nextPage = result.pagination.page + 1
            guard nextPage > requestedPage else { throw PangolinAPIError.decoding }
            requestedPage = nextPage
        }
    }

    func create(name: String, description: String) async throws -> Role {
        let response: PangolinResponse<Role> = try await client.send(
            .put, path: "/org/\(organizationId)/role",
            body: CreateBody(name: name, description: description)
        )
        return try response.requireRoleData()
    }

    func delete(roleId: Int, transferRoleId: Int) async throws {
        let response: PangolinResponse<PangolinEmptyResponse> = try await client.send(
            .delete, path: "/role/\(roleId)", body: DeleteBody(roleId: transferRoleId)
        )
        guard response.success, !response.error else {
            throw PangolinAPIError.serverRejected(status: response.status, message: response.message)
        }
    }
}

private extension PangolinResponse {
    func requireRoleData() throws -> Value {
        guard success, !error else {
            throw PangolinAPIError.serverRejected(status: status, message: message)
        }
        guard let data else { throw PangolinAPIError.decoding }
        return data
    }
}
